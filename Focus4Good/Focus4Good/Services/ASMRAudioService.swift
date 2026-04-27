@preconcurrency import AVFoundation

/// This service handles the actual audio playback for ASMR sounds.
/// It can stream audio from Supabase or play files stored locally in the app.
@MainActor
class ASMRAudioService {
    // Singleton instance to ensure only one sound plays at a time
    static let shared = ASMRAudioService()

    private var player: AVPlayer?
    private var timeObserver: Any?
    
    private(set) var isPlaying = false
    private(set) var duration: TimeInterval = 0
    
    private init() {}

    /// Starts playing a sound. It automatically decides whether to stream from Supabase or use a local file.
    func play(sound: AsmrSound) {
        stop() // Stop any currently playing sound

        // Set up the audio session so it can play even if the phone is on silent
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        let playerItem: AVPlayerItem
        
        // Check if the sound has a valid web URL (Supabase Storage)
        if let url = URL(string: sound.audioUrl), url.scheme != nil {
            playerItem = AVPlayerItem(url: url)
        } else {
            // Fallback: look for a local .mp3 file with the same name in the app bundle
            guard let bundleUrl = Bundle.main.url(forResource: sound.audioUrl, withExtension: "mp3") ?? 
                    Bundle.main.url(forResource: sound.name, withExtension: "mp3") else {
                print("ASMRAudioService: could not find audio in bundle for \(sound.name)")
                return
            }
            playerItem = AVPlayerItem(url: bundleUrl)
        }

        // Initialize the player with the chosen audio source
        player = AVPlayer(playerItem: playerItem)
        
        // Listen for when the sound finishes playing
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.isPlaying = false
            }
        }
        
        // Track the current playback progress (every 0.5 seconds)
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            // Use Task to safely jump back to the MainActor before updating state
            Task { @MainActor in
                guard let self = self else { return }
                if let currentItem = self.player?.currentItem {
                    let dur = CMTimeGetSeconds(currentItem.duration)
                    if dur.isFinite {
                        self.duration = dur
                    }
                }
            }
        }

        player?.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func resume() {
        player?.play()
        isPlaying = true
    }

    /// Completely stops the player and clears memory
    func stop() {
        player?.pause()
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        player = nil
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    var currentTime: TimeInterval {
        guard let player = player else { return 0 }
        return CMTimeGetSeconds(player.currentTime())
    }

    /// Moves the playhead to a specific time (used for the progress slider)
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func setVolume(_ volume: Float) {
        player?.volume = volume
    }
}
