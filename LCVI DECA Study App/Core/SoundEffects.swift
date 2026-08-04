//
//  SoundEffects.swift
//  LCVI DECA Study App
//
//  Short answer-feedback tones. Bundled audio, played locally — like the rest
//  of the app, nothing here touches the network.
//
//  The session uses `.ambient`, which means two things that matter for a study
//  app: whatever the student is already listening to keeps playing, and the
//  ring/silent switch mutes these tones the way people expect.
//

import AVFoundation
import Foundation

@MainActor
enum SoundEffects {

    enum Effect: CaseIterable {
        case correct
        case wrong
        case celebration
        case intro

        var fileName: String {
            switch self {
            case .correct:     return "answer-correct"
            case .wrong:       return "answer-wrong"
            case .celebration: return "badge-celebration"
            case .intro:       return "app-intro"
            }
        }

        var fileExtension: String {
            switch self {
            case .wrong:                return "wav"
            case .correct, .celebration, .intro: return "m4a"
            }
        }

        /// The wrong-answer tone sits lower so it never feels like a reprimand.
        var volume: Float {
            switch self {
            // Full volume: measured A-weighted, this clip still sits below the
            // celebration jingle, so there's no headroom to give away.
            case .correct:     return 1.00
            case .wrong:       return 0.45
            case .celebration: return 0.60
            // Measured A-weighted, this reveal still sits under the celebration
            // jingle even at full scale.
            case .intro:       return 1.00
            }
        }
    }

    /// Toggled from Settings, alongside haptics.
    static var enabled: Bool = true

    /// The selected sound pack, from the customise shop. Changing it drops the
    /// cached players so the next cue reloads from the new files.
    ///
    /// A pack is a filename suffix, and `prepare()` falls back to the base file
    /// whenever a pack is missing one. That means a half-populated pack
    /// degrades to the default tone rather than to silence, which is the
    /// failure mode you want for something bought in a shop.
    static var pack: String = "sound.default" {
        didSet {
            guard pack != oldValue else { return }
            players.removeAll()
        }
    }

    private static func candidates(for effect: Effect) -> [String] {
        guard pack != "sound.default" else { return [effect.fileName] }
        let suffix = pack.replacingOccurrences(of: "sound.", with: "")
        return ["\(effect.fileName)-\(suffix)", effect.fileName]
    }

    private static var players: [Effect: AVAudioPlayer] = [:]
    private static var sessionConfigured = false

    /// Loads and primes both tones so the first correct answer isn't late.
    static func prepare() {
        configureSession()
        for effect in Effect.allCases where players[effect] == nil {
            let url = candidates(for: effect).lazy.compactMap {
                Bundle.main.url(forResource: $0, withExtension: effect.fileExtension)
                    ?? Bundle.main.url(forResource: $0, withExtension: "wav")
            }.first
            guard let url, let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.volume = effect.volume
            player.prepareToPlay()
            players[effect] = player
        }
    }

    static func correct() { play(.correct) }
    static func wrong() { play(.wrong) }
    static func celebration() { play(.celebration) }
    static func intro() { play(.intro) }

    /// Used when a celebration is dismissed early, so the jingle doesn't carry
    /// on over the screen underneath.
    ///
    /// `fadeDuration` exists because stopping a sustained tone dead truncates
    /// the waveform at whatever amplitude it happened to be at, which is
    /// audible as a click. Short cues can stop hard; the intro's swell fades.
    /// The volume is restored afterwards so the next play isn't silent.
    static func stop(_ effect: Effect, fadeDuration: TimeInterval = 0) {
        guard let player = players[effect] else { return }
        guard fadeDuration > 0, player.isPlaying else {
            player.stop()
            player.currentTime = 0
            player.volume = effect.volume
            return
        }
        player.setVolume(0, fadeDuration: fadeDuration)
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) {
            player.stop()
            player.currentTime = 0
            player.volume = effect.volume
        }
    }

    /// Plays a pack's correct-answer tone without switching to that pack.
    ///
    /// Its own player, so auditioning a sound in the shop cannot evict the
    /// cached ones or leave the wrong pack loaded if the student decides not
    /// to buy. Held in a property because a local `AVAudioPlayer` is
    /// deallocated the moment the function returns and never makes a sound.
    static func preview(pack id: String) {
        guard enabled else { return }
        configureSession()
        let effect = Effect.correct
        let names = id == "sound.default"
            ? [effect.fileName]
            : ["\(effect.fileName)-\(id.replacingOccurrences(of: "sound.", with: ""))",
               effect.fileName]
        let url = names.lazy.compactMap {
            Bundle.main.url(forResource: $0, withExtension: effect.fileExtension)
                ?? Bundle.main.url(forResource: $0, withExtension: "wav")
        }.first
        guard let url, let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.volume = effect.volume
        previewPlayer = player
        player.play()
    }

    private static var previewPlayer: AVAudioPlayer?

    static func play(_ effect: Effect) {
        guard enabled else { return }
        prepare()
        guard let player = players[effect] else { return }
        // Restart rather than overlap — answers can come quickly in Exam Cram.
        player.currentTime = 0
        player.play()
    }

    private static func configureSession() {
        guard !sessionConfigured else { return }
        sessionConfigured = true
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }
}
