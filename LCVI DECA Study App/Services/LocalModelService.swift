//
//  LocalModelService.swift
//  LCVI DECA Study App
//
//  Optional download of a small local language model, for devices that cannot
//  run Apple's on-device model.
//
//  Why this exists
//  ---------------
//  Apple Foundation Models needs Apple Intelligence, which starts at the
//  iPhone 15 Pro. Most students are on older hardware, so the AI coaching in
//  this app is invisible to nearly all of them. This service offers a second
//  tier: a ~770 MB model the student can choose to download once.
//
//  How it stays inside the app's promises
//  --------------------------------------
//  §2 says no sign-in, no accounts, no remote APIs, no personal data leaving
//  the phone, and no internet *requirement*. All of that still holds:
//
//  - Nothing here is automatic. The student opts in explicitly.
//  - The only network call in the entire app is this one file fetch, from a
//    public host. No account, no telemetry, no personal data — the request
//    carries nothing about the student.
//  - Every AI path already degrades to the written `manual()` fallbacks, so
//    declining the download leaves a fully working offline app.
//  - Once downloaded, inference is local and the app never needs the network
//    again.
//
//  Wi-Fi only is enforced, not merely suggested: the session refuses cellular
//  and refuses "expensive" or "constrained" interfaces, so a personal hotspot
//  or Low Data Mode will not quietly burn 770 MB of someone's plan.
//

import Combine
import CryptoKit
import Foundation
import UIKit

// MARK: - Catalogue

/// The model this app offers, pinned by digest.
///
/// Picked for the *floor*, not the ceiling. The oldest device that can
/// realistically run a local model is the iPhone 11 (A13, 4 GB), where iOS
/// will terminate the app somewhere north of ~1.3 GB resident. A 1B model at
/// Q4_K_M leaves room for Core Data, the view tree and the KV cache; the next
/// size up does not.
enum LocalModelCatalog {
    static let displayName = "Llama 3.2 1B Instruct"
    static let quantisation = "Q4_K_M"

    static let remoteURL = URL(string:
        "https://huggingface.co/hugging-quants/Llama-3.2-1B-Instruct-Q4_K_M-GGUF/resolve/main/llama-3.2-1b-instruct-q4_k_m.gguf")!

    /// Exact byte count, used to show a truthful size before downloading and
    /// to reject a truncated file early.
    static let expectedBytes: Int64 = 807_690_656

    /// SHA-256 of the file. A model is executable content, so it is verified
    /// before it is ever kept — a corrupted or substituted file is discarded.
    static let sha256 = "1d0e9419ec4e12aef73ccf4ffd122703e94c48344a96bc7c5f0f2772c2152ce3"

    static let fileName = "llama-3.2-1b-instruct-q4_k_m.gguf"

    /// Required by the Llama 3.2 Community License, and shown wherever the
    /// download is offered.
    static let attribution = "Built with Llama"
    static let licenceNote = """
        \(displayName) is provided by Meta under the Llama 3.2 Community \
        License. It runs entirely on this phone once downloaded.
        """

    static var approximateMegabytes: Int { Int(expectedBytes / 1_000_000) }
}

// MARK: - State

enum LocalModelState: Equatable {
    /// Not enough memory to load a model without the system killing the app.
    case deviceTooSmall
    case notDownloaded
    case downloading(progress: Double, receivedBytes: Int64)
    case verifying
    case ready
    case failed(String)

    var isReady: Bool { self == .ready }

    var isBusy: Bool {
        switch self {
        case .downloading, .verifying: return true
        default: return false
        }
    }
}

// MARK: - Service

@MainActor
final class LocalModelService: NSObject, ObservableObject {

    @Published private(set) var state: LocalModelState = .notDownloaded

    private var session: URLSession?
    private var task: URLSessionDownloadTask?
    private var backgroundAssertion: UIBackgroundTaskIdentifier = .invalid

    /// A 1B model at Q4 needs roughly 1 GB resident once the KV cache is
    /// allocated. Devices reporting under ~3.5 GB of RAM — the iPhone 8 and
    /// everything of that era — would be terminated trying, so they are never
    /// offered the download in the first place.
    private static let minimumPhysicalMemory: UInt64 = 3_758_096_384

    static var deviceCanRunLocalModel: Bool {
        ProcessInfo.processInfo.physicalMemory >= minimumPhysicalMemory
    }

    override init() {
        super.init()
        refreshState()
    }

    // MARK: Location

    /// Application Support, not Documents: this is a cache-like asset the user
    /// did not author, and it must not show up in the Files app.
    private static var modelDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask)[0]
        return base.appendingPathComponent("LocalModel", isDirectory: true)
    }

    static var modelURL: URL {
        modelDirectory.appendingPathComponent(LocalModelCatalog.fileName)
    }

    /// Present and the right size. The digest is checked once at download
    /// time rather than on every launch — re-hashing 770 MB on a cold start
    /// would cost seconds for no benefit.
    static var isModelPresent: Bool {
        let url = modelURL
        guard let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
              let size = values.fileSize else { return false }
        return Int64(size) == LocalModelCatalog.expectedBytes
    }

    func refreshState() {
        guard Self.deviceCanRunLocalModel else { state = .deviceTooSmall; return }
        if case .downloading = state { return }
        if case .verifying = state { return }
        state = Self.isModelPresent ? .ready : .notDownloaded
    }

    // MARK: Download

    func startDownload() {
        guard Self.deviceCanRunLocalModel else { state = .deviceTooSmall; return }
        guard !state.isBusy, !Self.isModelPresent else { return }

        guard hasRoomOnDisk() else {
            state = .failed("Not enough free space. This needs about \(LocalModelCatalog.approximateMegabytes) MB.")
            return
        }

        let config = URLSessionConfiguration.default
        // Wi-Fi only, enforced at the socket rather than trusted to the UI.
        config.allowsCellularAccess = false
        config.allowsExpensiveNetworkAccess = false   // hotspots, cellular-backed
        config.allowsConstrainedNetworkAccess = false // Low Data Mode
        config.waitsForConnectivity = false
        config.timeoutIntervalForResource = 60 * 60

        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        self.session = session

        state = .downloading(progress: 0, receivedBytes: 0)
        beginBackgroundAssertion()

        let task = session.downloadTask(with: LocalModelCatalog.remoteURL)
        self.task = task
        task.resume()
    }

    func cancelDownload() {
        task?.cancel()
        task = nil
        session?.invalidateAndCancel()
        session = nil
        endBackgroundAssertion()
        refreshState()
    }

    func deleteModel() {
        cancelDownload()
        try? FileManager.default.removeItem(at: Self.modelURL)
        state = Self.deviceCanRunLocalModel ? .notDownloaded : .deviceTooSmall
    }

    private func hasRoomOnDisk() -> Bool {
        let needed = LocalModelCatalog.expectedBytes + 150_000_000  // slack for the move
        guard let values = try? URL(fileURLWithPath: NSHomeDirectory())
            .resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
              let free = values.volumeAvailableCapacityForImportantUsage else { return true }
        return free > needed
    }

    // MARK: Backgrounding
    //
    // A plain session is cancelled when the app is suspended. The assertion
    // buys the few minutes iOS grants, which covers switching apps briefly.
    // The UI tells the student to keep the app open regardless — this is a
    // safety net, not a promise.

    private func beginBackgroundAssertion() {
        endBackgroundAssertion()
        backgroundAssertion = UIApplication.shared.beginBackgroundTask(withName: "ModelDownload") { [weak self] in
            Task { @MainActor in self?.endBackgroundAssertion() }
        }
    }

    private func endBackgroundAssertion() {
        guard backgroundAssertion != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundAssertion)
        backgroundAssertion = .invalid
    }

    // MARK: Verification

    /// Streams the file through SHA-256 in chunks. Hashing 770 MB in one
    /// `Data` would be a guaranteed termination on a 4 GB phone.
    nonisolated private static func digest(of url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        var hasher = SHA256()
        while autoreleasepool(invoking: {
            guard let chunk = try? handle.read(upToCount: 4 * 1024 * 1024), !chunk.isEmpty else {
                return false
            }
            hasher.update(data: chunk)
            return true
        }) {}
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Download delegate

extension LocalModelService: URLSessionDownloadDelegate {

    nonisolated func urlSession(_ session: URLSession,
                                downloadTask: URLSessionDownloadTask,
                                didWriteData bytesWritten: Int64,
                                totalBytesWritten: Int64,
                                totalBytesExpectedToWrite: Int64) {
        let total = totalBytesExpectedToWrite > 0
            ? totalBytesExpectedToWrite
            : LocalModelCatalog.expectedBytes
        let fraction = min(max(Double(totalBytesWritten) / Double(total), 0), 1)
        Task { @MainActor [weak self] in
            guard let self, self.state.isBusy || self.state == .notDownloaded else { return }
            self.state = .downloading(progress: fraction, receivedBytes: totalBytesWritten)
        }
    }

    nonisolated func urlSession(_ session: URLSession,
                                downloadTask: URLSessionDownloadTask,
                                didFinishDownloadingTo location: URL) {
        // The delegate's temp file is deleted the moment this returns, so the
        // move has to happen here, synchronously, off the main actor.
        let fm = FileManager.default
        let staging = fm.temporaryDirectory
            .appendingPathComponent("model-staging-\(UUID().uuidString).gguf")
        do {
            try fm.moveItem(at: location, to: staging)
        } catch {
            Task { @MainActor [weak self] in
                self?.finish(.failed("Could not save the download."))
            }
            return
        }

        Task { @MainActor [weak self] in self?.state = .verifying }

        Task.detached(priority: .utility) { [weak self] in
            defer { try? FileManager.default.removeItem(at: staging) }

            let size = (try? staging.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            guard Int64(size) == LocalModelCatalog.expectedBytes else {
                await self?.finish(.failed("The download was incomplete. Try again on a stable Wi-Fi network."))
                return
            }
            guard let hash = LocalModelService.digest(of: staging),
                  hash == LocalModelCatalog.sha256 else {
                await self?.finish(.failed("The downloaded file did not match its checksum and was discarded."))
                return
            }
            await self?.install(from: staging)
        }
    }

    nonisolated func urlSession(_ session: URLSession,
                                task: URLSessionTask,
                                didCompleteWithError error: Error?) {
        guard let error = error as NSError? else { return }
        // A success path also lands here with a nil error; only react to real
        // failures, and say something useful about the Wi-Fi-only rule.
        let message: String
        switch error.code {
        case NSURLErrorCancelled:
            return
        case NSURLErrorNotConnectedToInternet,
             NSURLErrorNetworkConnectionLost,
             NSURLErrorDataNotAllowed:
            message = "Wi-Fi is needed for this download. Connect to Wi-Fi and try again."
        default:
            message = "The download failed. Connect to Wi-Fi and try again."
        }
        Task { @MainActor [weak self] in
            guard let self, self.state.isBusy else { return }
            self.finish(.failed(message))
        }
    }

    private func install(from staging: URL) {
        let fm = FileManager.default
        do {
            try fm.createDirectory(at: Self.modelDirectory,
                                   withIntermediateDirectories: true)
            if fm.fileExists(atPath: Self.modelURL.path) {
                try fm.removeItem(at: Self.modelURL)
            }
            try fm.copyItem(at: staging, to: Self.modelURL)

            // 770 MB has no business in an iCloud backup — it is re-downloadable.
            var url = Self.modelURL
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? url.setResourceValues(values)

            finish(.ready)
        } catch {
            finish(.failed("Could not save the model to this device."))
        }
    }

    private func finish(_ newState: LocalModelState) {
        task = nil
        session?.finishTasksAndInvalidate()
        session = nil
        endBackgroundAssertion()
        state = newState
    }
}
