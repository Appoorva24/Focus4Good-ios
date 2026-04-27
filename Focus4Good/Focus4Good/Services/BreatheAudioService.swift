@preconcurrency import AVFoundation

/// This service handles the voice guidance for the Breathing session.
/// It uses high-quality text-to-speech to guide the user through Inhaling, Holding, and Exhaling.
@MainActor
class BreatheAudioService: NSObject, AVSpeechSynthesizerDelegate {

    static let shared = BreatheAudioService()

    /// A callback that is triggered when the AI finishes speaking a sentence.
    /// Used by the UI to wait before moving to the next breathing phase.
    var onSpeechFinished: (() -> Void)?

    // MARK: - Private State
    private let synthesizer = AVSpeechSynthesizer()
    private var selectedVoice: AVSpeechSynthesisVoice?

    private override init() {
        super.init()
        synthesizer.delegate = self
        // Try to pick a gentle female voice for a more relaxing experience
        selectedVoice = pickFemaleVoice()
    }

    // MARK: - AVSpeechSynthesizerDelegate

    /// This is called automatically by iOS when a voice instruction finishes.
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.onSpeechFinished?()
        }
    }

    // MARK: - Voice Selection

    /// Attempts to find premium, high-quality female voices like "Zoe" or "Ava".
    private func pickFemaleVoice() -> AVSpeechSynthesisVoice? {
        let preferred: [String] = [
            "com.apple.voice.premium.en-US.Zoe",
            "com.apple.voice.premium.en-US.Ava",
            "com.apple.voice.premium.en-GB.Stephanie",
            "com.apple.voice.enhanced.en-US.Samantha",
            "com.apple.voice.enhanced.en-US.Ava",
            "com.apple.voice.enhanced.en-GB.Stephanie",
            "com.apple.voice.compact.en-US.Samantha",
        ]

        for id in preferred {
            if let voice = AVSpeechSynthesisVoice(identifier: id) {
                return voice
            }
        }

        // Fallback to default US English if no premium voice is found
        return AVSpeechSynthesisVoice(language: "en-US")
    }

    // MARK: - Guided Instructions

    /// Welcome message when starting the session.
    func speakIntro(cycles: Int) {
        configureAudioSession()
        let text = "Welcome to your breathing space. "
            + "Find a comfortable position. "
            + "We will practice \(cycles) \(cycles == 1 ? "round" : "rounds") "
            + "of the 4, 7, 8 breathing technique together. "
            + "Breathe in for 4 seconds, hold for 7, and breathe out slowly for 8. "
            + "Let go of any tension. Let's begin."
        speakCalm(text)
    }

    /// Tells the user whether to Inhale, Hold, or Exhale.
    func speakPhase(_ phaseName: String, cycle: Int, totalCycles: Int) {
        configureAudioSession()

        let text: String
        switch phaseName {
        case "Breathe In":
            if cycle == 1 {
                text = "Breathe in slowly through your nose. Fill your lungs gently."
            } else {
                text = "Breathe in. Slowly and deeply."
            }
        case "Hold":
            text = "Hold your breath. Stay calm and relaxed."
        case "Breathe Out":
            if cycle == totalCycles {
                text = "Now breathe out slowly through your mouth. Let everything go."
            } else {
                text = "Breathe out gently through your mouth. Release all the tension."
            }
        default:
            text = phaseName
        }

        speakCalm(text)
    }

    /// Announce the transition to the next cycle.
    func speakCycleTransition(currentCycle: Int, totalCycles: Int) {
        configureAudioSession()
        let remaining = totalCycles - currentCycle
        let text: String
        if remaining == 1 {
            text = "Beautiful. One more round to go. You're doing wonderfully."
        } else {
            text = "Well done. \(remaining) more \(remaining == 1 ? "round" : "rounds") remaining. "
                + "Keep this gentle rhythm."
        }
        speakCalm(text)
    }

    /// Final success message when the session is complete.
    func speakCompletion(cycles: Int) {
        configureAudioSession()
        let text = "You did it. \(cycles) \(cycles == 1 ? "round" : "rounds") complete. "
            + "Take a moment to notice how your body feels. "
            + "Gently open your eyes when you are ready. "
            + "You've earned your focus points. Well done."
        speakCalm(text)
    }

    // MARK: - Status & Control

    /// Returns true if the AI is currently talking.
    var isSpeaking: Bool {
        synthesizer.isSpeaking
    }

    /// Stops all speech immediately and clears the audio session.
    func stopAll() {
        onSpeechFinished = nil
        synthesizer.stopSpeaking(at: .immediate)
        try? AVAudioSession.sharedInstance().setActive(
            false, options: .notifyOthersOnDeactivation
        )
    }

    // MARK: - Private Helpers

    /// Starts speaking a text with a meditative, slow delivery.
    private func speakCalm(_ text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .word) // Stop naturally at the end of the current word
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = selectedVoice
        utterance.rate = 0.38 // Very slow pace for breathing
        utterance.pitchMultiplier = 1.05
        utterance.volume = 0.85
        utterance.preUtteranceDelay = 0.3
        utterance.postUtteranceDelay = 0.5

        synthesizer.speak(utterance)
    }

    /// Configures the phone's audio session to allow playback (even on silent) and dim other background music.
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.duckOthers])
        try? session.setActive(true)
    }
}
