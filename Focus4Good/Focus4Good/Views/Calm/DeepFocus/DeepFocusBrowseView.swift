import SwiftUI
import AVFoundation

// MARK: - DeepFocusBrowseView

struct DeepFocusBrowseView: View {

    @Environment(CalmCentreStore.self) private var store
    @Environment(UserStore.self) private var userStore
    @Environment(\.dismiss) private var dismiss

    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var hasStarted = false
    @State private var elapsed: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var isSeeking = false
    @State private var timer: Timer?
    @State private var volume: Double = 0.5
    @State private var isMuted = false
    @State private var isFavourite = false
    @State private var showCompletion = false

    private static let favouriteKey = "deep_focus_favourite"
    private var currentUserId: UUID { userStore.currentUser?.id ?? UUID() }

    private var remaining: TimeInterval {
        max(0, duration - elapsed)
    }

    var body: some View {
        GeometryReader { geo in
            let artworkSize = max(0, geo.size.width - 56)

            ZStack {

                VStack(spacing: 0) {
                    Spacer()

                    // Artwork
                    Image("guided_meditation")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: artworkSize, height: artworkSize)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)

                    Spacer().frame(height: 32)

                    // Title + Favourite
                    titleRow.padding(.horizontal, 28)

                    Spacer().frame(height: 20)

                    // Progress
                    progressSection.padding(.horizontal, 28)

                    Spacer().frame(height: 36)

                    // Controls
                    playbackControls

                    Spacer().frame(height: 36)

                    // Volume
                    volumeSlider.padding(.horizontal, 28)

                    Spacer()
                }
                .frame(maxWidth: .infinity)

                if showCompletion {
                    completionOverlay
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showCompletion)
        }
        .background(AppTheme.appGradient.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadFavourite() }
        .onDisappear { 
            stopTimer() 
            logCurrentSessionIfNeeded()
        }
    }

    // MARK: - Subviews

    private var titleRow: some View {
        HStack {
            Text("Guided Meditation")
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1)

            Spacer()

            Button { toggleFavourite() } label: {
                Image(systemName: isFavourite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(isFavourite ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var progressSection: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { elapsed },
                    set: { newValue in
                        elapsed = newValue
                        audioPlayer?.currentTime = newValue
                    }
                ),
                in: 0...max(duration, 1)
            ) { editing in
                isSeeking = editing
                if !editing { audioPlayer?.currentTime = elapsed }
            }
            .tint(Color(.systemGray))

            HStack {
                Text(formatTime(elapsed))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                Spacer()

                Text("-\(formatTime(remaining))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    private var playbackControls: some View {
        HStack(spacing: 44) {
            Button {
                isMuted.toggle()
                audioPlayer?.volume = isMuted ? 0 : Float(volume)
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            Button {
                if isPlaying { pauseSession() }
                else if hasStarted { resumeSession() }
                else { startSession() }
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(Color.accentColor))
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            Button { resetSession() } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
        }
    }

    private var volumeSlider: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.fill")
                .font(.caption)
                .foregroundStyle(.secondary)

            Slider(value: $volume, in: 0...1)
                .tint(Color(.systemGray))
                .onChange(of: volume) { _, newValue in
                    audioPlayer?.volume = Float(newValue)
                }

            Image(systemName: "speaker.wave.3.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showCompletion = false
                    dismiss()
                }

            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)

                Text("Namaste 🙏")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("You completed a 5-minute\nGuided Meditation session")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("+ 50 Focus Points")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)

                Button {
                    showCompletion = false
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            Capsule()
                                .fill(Color.accentColor)
                                .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                }
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    // MARK: - Favourite

    private func loadFavourite() {
        isFavourite = UserDefaults.standard.bool(forKey: Self.favouriteKey)
    }

    private func toggleFavourite() {
        isFavourite.toggle()
        UserDefaults.standard.set(isFavourite, forKey: Self.favouriteKey)
    }

    // MARK: - Audio Player Logic

    private func setupAudio() {
        guard let url = Bundle.main.url(forResource: "guided_meditation", withExtension: "mp4") else {
            print("Could not find guided_meditation.mp4 in bundle")
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try? session.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = Float(volume)
            duration = audioPlayer?.duration ?? 0
        } catch {
            print("Failed to load guided_meditation.mp4: \(error)")
        }
    }

    // MARK: - Session Logic

    private func startSession() {
        if audioPlayer == nil { setupAudio() }
        elapsed = 0
        hasStarted = true
        isPlaying = true
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
        startTimer()
    }

    private func pauseSession() {
        isPlaying = false
        audioPlayer?.pause()
        stopTimer()
    }

    private func resumeSession() {
        isPlaying = true
        audioPlayer?.play()
        startTimer()
    }

    private func resetSession() {
        stopTimer()
        logCurrentSessionIfNeeded()
        elapsed = 0
        hasStarted = false
        isPlaying = false
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
    }
    
    private func logCurrentSessionIfNeeded() {
        if hasStarted && elapsed > 0 {
            let loggedDuration = Int(elapsed)
            Task {
                await store.logGuidedMeditationSession(
                    userId: currentUserId,
                    meditationName: "Guided Meditation",
                    durationSeconds: loggedDuration
                )
            }
            hasStarted = false // Prevent duplicate logging
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            guard !isSeeking else { return }
            elapsed = audioPlayer?.currentTime ?? 0
            if elapsed >= duration && duration > 0 { completeSession() }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func completeSession() {
        stopTimer()
        isPlaying = false
        hasStarted = false
        audioPlayer?.stop()

        Task {
            await store.logGuidedMeditationSession(
                userId: currentUserId,
                meditationName: "Guided Meditation",
                durationSeconds: Int(duration)
            )
        }

        showCompletion = true
    }
}

#Preview {
    NavigationStack {
        DeepFocusBrowseView()
            .environment(CalmCentreStore.shared)
    }
}
