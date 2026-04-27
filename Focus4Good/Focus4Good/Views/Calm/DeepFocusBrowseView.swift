import SwiftUI
import AVFoundation
import Supabase

// MARK: - DeepFocusBrowseView
/// This view allows users to stream a high-quality guided meditation directly from Supabase.
/// It handles audio playback, progress tracking, and reward points.
struct DeepFocusBrowseView: View {

    @Environment(CalmCentreStore.self) private var store
    @Environment(UserStore.self) private var userStore
    @Environment(\.dismiss) private var dismiss

    // MARK: - Playback State
    @State private var player: AVPlayer?
    @State private var timeObserver: Any?
    @State private var isPlaying = false
    @State private var hasStarted = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var volume: Double = 0.5
    @State private var isMuted = false
    @State private var isFavourite = false
    @State private var showCompletion = false
    @State private var isSeeking = false

    // MARK: - Loading State
    @State private var isLoadingAudio = false
    @State private var audioURL: URL?
    @State private var loadError: String?

    private var userId: UUID? {
        userStore.currentUser?.id
    }

    private var remaining: TimeInterval {
        max(0, duration - currentTime)
    }

    /// Access the Supabase client for storage fetching
    private var client: SupabaseClient { SupabaseManager.shared.client }

    var body: some View {
        GeometryReader { geo in
            let artworkSize = max(0, geo.size.width - 56)

            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Visual artwork for the meditation session
                    Image("deep_focus_meditation")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: artworkSize, height: artworkSize)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)

                    Spacer().frame(height: 32)

                    // Title section
                    titleRow.padding(.horizontal, 28)

                    Spacer().frame(height: 20)

                    // Displays either loading indicator, error message, or the progress bar
                    if isLoadingAudio {
                        loadingSection.padding(.horizontal, 28)
                    } else if let error = loadError {
                        errorSection(error).padding(.horizontal, 28)
                    } else {
                        progressSection.padding(.horizontal, 28)
                    }

                    Spacer().frame(height: 36)

                    // Play/Pause and Reset buttons
                    playbackControls

                    Spacer().frame(height: 36)

                    // Volume control slider
                    volumeSlider.padding(.horizontal, 28)

                    Spacer()
                }
                .frame(maxWidth: .infinity)

                // Success screen shown when the meditation ends
                if showCompletion {
                    completionOverlay
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showCompletion)
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Fetch the audio URL from Supabase when the screen appears
            if audioURL == nil {
                Task { await fetchAudioFromSupabase() }
            }
        }
        .onDisappear {
            // Clean up the audio player to save memory and battery
            cleanupPlayer()
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

            Button { isFavourite.toggle() } label: {
                Image(systemName: isFavourite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(isFavourite ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var loadingSection: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Preparing your meditation…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 60)
    }

    private func errorSection(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                Task { await fetchAudioFromSupabase() }
            } label: {
                Text("Retry Loading")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .frame(height: 60)
    }

    private var progressSection: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { currentTime },
                    set: { newValue in
                        currentTime = newValue
                        seekTo(newValue)
                    }
                ),
                in: 0...max(duration, 1)
            ) { editing in
                isSeeking = editing
            }
            .tint(Color(.systemGray))

            HStack {
                Text(formatTime(currentTime))
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
                player?.isMuted = isMuted
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.title2)
            }

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
            }
            .disabled(audioURL == nil || isLoadingAudio)

            Button { resetSession() } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
            }
        }
        .buttonStyle(.plain)
    }

    private var volumeSlider: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.fill")
                .font(.caption)
                .foregroundStyle(.secondary)

            Slider(value: $volume, in: 0...1)
                .tint(Color(.systemGray))
                .onChange(of: volume) { _, newValue in
                    player?.volume = Float(newValue)
                }

            Image(systemName: "speaker.wave.3.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)

                Text("Peaceful Moment")
                    .font(.title2.bold())

                Text("You finished your guided meditation session. Notice how you feel right now.")
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
                    Text("Finish")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(32)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Logic

    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    /// Fetches the direct streaming link from Supabase Storage
    private func fetchAudioFromSupabase() async {
        isLoadingAudio = true
        loadError = nil

        do {
            let publicURL = try client.storage
                .from("guided_meditation")
                .getPublicURL(path: "Breathing Meditation 2009.mp3")

            audioURL = publicURL
            isLoadingAudio = false
        } catch {
            loadError = "Could not load audio. Please check your connection."
            isLoadingAudio = false
        }
    }

    /// Sets up the AVPlayer for cloud streaming
    private func setupPlayer(url: URL) {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.duckOthers])
        try? session.setActive(true)

        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.volume = Float(volume)
        player?.isMuted = isMuted

        // Update progress bar as audio plays
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            // Directly update state on the MainActor
            Task { @MainActor in
                guard !isSeeking else { return }
                currentTime = CMTimeGetSeconds(time)
                
                if let item = player?.currentItem {
                    let dur = CMTimeGetSeconds(item.duration)
                    if dur.isFinite && dur > 0 { duration = dur }
                }
            }
        }

        // Detect when the meditation finishes
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in completeSession() }
    }

    private func cleanupPlayer() {
        player?.pause()
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        player = nil
    }

    private func seekTo(_ time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    private func startSession() {
        guard let url = audioURL else { return }
        if player == nil { setupPlayer(url: url) }
        player?.play()
        hasStarted = true
        isPlaying = true
    }

    private func pauseSession() {
        player?.pause()
        isPlaying = false
    }

    private func resumeSession() {
        player?.play()
        isPlaying = true
    }

    private func resetSession() {
        player?.pause()
        seekTo(0)
        currentTime = 0
        hasStarted = false
        isPlaying = false
    }

    /// Logs the completed session to Supabase
    private func completeSession() {
        player?.pause()
        isPlaying = false
        hasStarted = false

        Task {
            guard let uid = userId else { return }
            await store.logGuidedMeditationSession(
                userId: uid,
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
            .environment(UserStore.shared)
    }
}

