import AVFoundation

//Sound-to-File Mapping

private func getFileName(for soundName: String) -> String {
    let lowerName = soundName.lowercased()
    if lowerName.contains("rain") || lowerName.contains("water") || lowerName.contains("ocean") || lowerName.contains("stream") {
        return "soft_rain_asmr"
    } else if lowerName.contains("typing") || lowerName.contains("keyboard") || lowerName.contains("mechanical") {
        return "keyboard_typing_asmr"
    } else if lowerName.contains("noise") || lowerName.contains("hum") || lowerName.contains("fan") {
        return "white_noise"
    } else {
        return "nature_and_calm"
    }
}

import Observation

// MARK: - ASMRAudioService

@Observable
class ASMRAudioService: @unchecked Sendable {


    //prevents two different sounds from playing at the same time
    static let shared = ASMRAudioService()

    private var audioPlayer: AVAudioPlayer?
    private(set) var isPlaying = false
    private(set) var currentSoundName: String?
    
    private var sessionStartTime: Date?
    private var accumulatedSessionTime: TimeInterval = 0

    private init() {}


    /// Whether the given sound is already loaded (playing or paused).
    func isLoaded(soundName: String) -> Bool {
        currentSoundName == soundName && audioPlayer != nil
    }

    func play(soundName: String) {
        stop() // This will log any previous session

        // Configure audio session
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        // Look up the file name using the dynamic matcher
        let fileName = getFileName(for: soundName)

        // Try to find the audio file in the bundle
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("ASMRAudioService: could not find \(fileName).mp3 in bundle")
            return
        }


        //starting the player
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = 0  // Play once (timer controls end)
            audioPlayer?.volume = 0.5
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            currentSoundName = soundName
            isPlaying = true
            sessionStartTime = Date()
        } catch {
            print("ASMRAudioService: failed to play — \(error)")
        }
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        if let start = sessionStartTime {
            accumulatedSessionTime += Date().timeIntervalSince(start)
            sessionStartTime = nil
        }
    }

    func resume() {
        audioPlayer?.play()
        isPlaying = true
        sessionStartTime = Date()
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        currentSoundName = nil
        isPlaying = false
        if let start = sessionStartTime {
            accumulatedSessionTime += Date().timeIntervalSince(start)
            sessionStartTime = nil
        }
        logCurrentSession()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    private func logCurrentSession() {
        if accumulatedSessionTime > 0 {
            let duration = Int(accumulatedSessionTime)
            // Use Task for async logging
            Task { @MainActor in
                if let userId = UserStore.shared.currentUser?.id {
                    await CalmCentreStore.shared.logAsmrSessionTime(durationSeconds: duration, userId: userId)
                }
            }
        }
        accumulatedSessionTime = 0
    }

    //Duration & Current Time

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
