import SwiftUI

struct CalmCentreView: View {

    @State private var showBraindump = false
    @State private var showBreathe = false
    @State private var showJPMR = false
    @State private var showASMR = false
    @State private var showDeepFocus = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Button { showBraindump = true } label: { braindumpCard }
                        .buttonStyle(.plain)

                    relaxationToolsSection
                    dailyTipRow
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Calm Centre")
            .navigationDestination(isPresented: $showBraindump) { BraindumpPasswordView() }
            .navigationDestination(isPresented: $showBreathe) { BreatheSessionView() }
            .navigationDestination(isPresented: $showJPMR) { JPMRSessionView() }
            .navigationDestination(isPresented: $showASMR) { SensorySootheView() }
            .navigationDestination(isPresented: $showDeepFocus) { DeepFocusBrowseView() }
        }
    }

    // MARK: - Subviews

    private var braindumpCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "pencil.and.list.clipboard")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                Spacer()

                Text("Top Choice")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.accentColor.opacity(0.15)))
            }

            Text("Braindump")
                .font(.title3)
                .fontWeight(.bold)

            Text("Get the noise out of your head. Write it down here to clear your mind instantly")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }

    private var relaxationToolsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Relaxation Tools")
                .font(.title3)
                .fontWeight(.bold)

            LazyVGrid(columns: columns, spacing: 16) {
                Button { showBreathe = true } label: {
                    toolCard(icon: "wind", title: "Breathe", subtitle: "4-7-8 Technique")
                }
                .buttonStyle(.plain)

                Button { showJPMR = true } label: {
                    toolCard(icon: "figure.walk", title: "Unwind Body", subtitle: "JPMR Muscle Relax")
                }
                .buttonStyle(.plain)

                Button { showASMR = true } label: {
                    toolCard(icon: "speaker.wave.3", title: "Sensory Soothe", subtitle: "ASMR Sounds")
                }
                .buttonStyle(.plain)

                Button { showDeepFocus = true } label: {
                    toolCard(icon: "leaf", title: "Deep Focus", subtitle: "Guided Meditation")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toolCard(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.accentColor.opacity(0.12)))

            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }

    private var dailyTipRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Tip")
                    .font(.subheadline)
                    .fontWeight(.bold)

                Text("Focus on exhale helps maintain stress")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    CalmCentreView()
        .environment(CalmCentreStore.shared)
}
