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

    private init() {}


    /// Whether the given sound is already loaded (playing or paused).
    func isLoaded(soundName: String) -> Bool {
        currentSoundName == soundName && audioPlayer != nil
    }

    func play(soundName: String) {
        stop()

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
        currentSoundName = nil
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
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
