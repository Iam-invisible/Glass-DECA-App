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

    private static var players: [Effect: AVAudioPlayer] = [:]
    private static var sessionConfigured = false

    /// Loads and primes both tones so the first correct answer isn't late.
    static func prepare() {
        configureSession()
        for effect in Effect.allCases where players[effect] == nil {
            guard let url = Bundle.main.url(forResource: effect.fileName,
                                            withExtension: effect.fileExtension),
                  let player = try? AVAudioPlayer(contentsOf: url) else { continue }
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
    static func stop(_ effect: Effect) {
        players[effect]?.stop()
        players[effect]?.currentTime = 0
    }

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
