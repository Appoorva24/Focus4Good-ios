@preconcurrency import AVFoundation

/// This service handles the voice guidance for the JPMR (Jacobson's Progressive Muscle Relaxation) session.
/// It uses high-quality text-to-speech to walk the user through tensing and releasing muscles.
@MainActor
class JPMRAudioService: NSObject, AVSpeechSynthesizerDelegate {

    static let shared = JPMRAudioService()

    /// A callback that is triggered when the AI finishes speaking a sentence.
    /// Used by the UI to wait for the voice to finish before moving to the next muscle group.
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
    func speakPreparation(groupCount: Int) {
        configureAudioSession()
        let text = "Welcome to your progressive muscle relaxation session. "
            + "We will work through \(groupCount) muscle \(groupCount == 1 ? "group" : "groups") together. "
            + "Find a comfortable position and close your eyes. "
            + "Take a few slow, deep breaths to settle in."
        speakCalm(text)
    }

    /// Tells the user to tense a specific muscle.
    func speakTense(muscleName: String, instruction: String) {
        configureAudioSession()
        let text = "\(muscleName). "
            + "Inhale, and tense now. "
            + "\(instruction). "
            + "Hold the tension firmly."
        speakCalm(text)
    }

    /// Tells the user to release the tension and relax.
    func speakRest(muscleName: String, releaseNote: String) {
        configureAudioSession()
        let text = "Release. Let go completely. "
            + "\(releaseNote). "
            + "Notice the difference between tension and relaxation."
        speakCalm(text)
    }

    /// Guides the transition to the next muscle group in the list.
    func speakGroupTransition(nextName: String, currentIndex: Int, totalGroups: Int) {
        configureAudioSession()
        let remaining = totalGroups - currentIndex
        let text: String
        if remaining <= 2 {
            text = "Almost there. Let's move to your \(nextName.lowercased())."
        } else {
            text = "Good. Now let's move to your \(nextName.lowercased())."
        }
        speakCalm(text)
    }

    /// Final instructions for ending the session.
    func speakEndingStep(title: String, instruction: String) {
        configureAudioSession()
        let cleaned = instruction.replacingOccurrences(of: "\n", with: ". ")
        let text = "\(title). \(cleaned)"
        speakCalm(text)
    }

    /// Success message when the whole session is complete.
    func speakCompletion(groupCount: Int) {
        configureAudioSession()
        let text = "Wonderful. You've completed your progressive muscle relaxation session, "
            + "working through \(groupCount) muscle \(groupCount == 1 ? "group" : "groups"). "
            + "Take a moment to notice how calm and relaxed your body feels. "
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

    /// Starts speaking a text with calm, slow, and soothing settings.
    private func speakCalm(_ text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .word) // Stop naturally at the end of the current word
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = selectedVoice
        utterance.rate = 0.38 // Slow speed for relaxation
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

