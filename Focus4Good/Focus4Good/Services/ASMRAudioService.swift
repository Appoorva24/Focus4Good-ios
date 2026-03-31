//
//  ASMRAudioService.swift
//  Focus4Good
//
//  Created by Shreya on 23/03/26.
//

import AVFoundation

// MARK: - Sound-to-File Mapping

/// Maps display names to their actual bundle file names (without extension).
private let soundFileMapping: [String: String] = [
    "Soft Rain":       "softrainasmr",
    "Typing":          "Keyboardtypingasmr",
    "Crinkling":       "crinkling",
    "Tapping":         "tapping",
    "White Noise":     "whitenoise",
    "Forest":          "Forest",
    "Nature & Calm":   "natureAndCalm",
]

// MARK: - ASMRAudioService

class ASMRAudioService: @unchecked Sendable {

    static let shared = ASMRAudioService()

    private var audioPlayer: AVAudioPlayer?
    private(set) var isPlaying = false

    init() {}

    // MARK: Playback Controls

    func play(soundName: String) {
        stop()

        // Configure audio session
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        // Look up the file name from the mapping
        let fileName = soundFileMapping[soundName] ?? soundName

        // Try to find the audio file in the bundle
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("ASMRAudioService: could not find \(fileName).mp3 in bundle")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = 0  // Play once (timer controls end)
            audioPlayer?.volume = 0.5
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("ASMRAudioService: failed to play — \(error)")
        }
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }

    func resume() {
        audioPlayer?.play()
        isPlaying = true
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: Duration & Current Time

    /// Total duration of the loaded audio in seconds.
    var duration: TimeInterval {
        audioPlayer?.duration ?? 0
    }

    /// Current playback position in seconds.
    var currentTime: TimeInterval {
        audioPlayer?.currentTime ?? 0
    }

    // MARK: Seeking

    /// Seek to a specific time in seconds.
    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        let clampedTime = max(0, min(time, player.duration))
        player.currentTime = clampedTime
    }

    // MARK: Volume

    func setVolume(_ volume: Float) {
        audioPlayer?.volume = volume
    }
}
