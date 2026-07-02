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

    // Each tool gets a unique accent color
    private struct ToolInfo {
        let icon: String
        let imageName: String
        let title: String
        let subtitle: String
        let detail: String
        let color: Color
        let gradientEnd: Color
    }

    private let tools: [ToolInfo] = [
        ToolInfo(icon: "wind", imageName: "calm_breathe", title: "Breathe", subtitle: "4-7-8 Technique", detail: "15 min session", color: Color(hex: "0EA5E9"), gradientEnd: Color(hex: "38BDF8")),
        ToolInfo(icon: "figure.walk", imageName: "calm_unwind", title: "Unwind Body", subtitle: "JPMR Muscle Relax", detail: "30 min program", color: Color(hex: "8B5CF6"), gradientEnd: Color(hex: "A78BFA")),
        ToolInfo(icon: "speaker.wave.3", imageName: "calm_sensory", title: "Sensory Soothe", subtitle: "ASMR Sounds", detail: "Next: Ocean Waves", color: Color(hex: "EC4899"), gradientEnd: Color(hex: "F472B6")),
        ToolInfo(icon: "leaf", imageName: "calm_deepfocus", title: "Deep Focus", subtitle: "Guided Meditation", detail: "Session: 15 min", color: Color(hex: "22C55E"), gradientEnd: Color(hex: "4ADE80")),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Button { showBraindump = true } label: { braindumpCard }
                        .buttonStyle(.plain)
                        .staggeredFadeIn(index: 0)

                    relaxationToolsSection
                        .staggeredFadeIn(index: 1)

                    dailyTipRow
                        .staggeredFadeIn(index: 2)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(calmBackground)
            .navigationTitle("Calm Centre")
            .navigationDestination(isPresented: $showBraindump) { BraindumpPasswordView() }
            .navigationDestination(isPresented: $showBreathe) { BreatheSessionView() }
            .navigationDestination(isPresented: $showJPMR) { JPMRSessionView() }
            .navigationDestination(isPresented: $showASMR) { SensorySootheView() }
            .navigationDestination(isPresented: $showDeepFocus) { DeepFocusBrowseView() }
        }
    }

    // MARK: - Background

    private var calmBackground: some View {
        ZStack {
            AppTheme.pageGradient
                .ignoresSafeArea()

            // Subtle sage orb
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Circle()
                        .fill(AppTheme.sage.opacity(0.05))
                        .frame(width: 200, height: 200)
                        .blur(radius: 60)
                        .offset(x: 50, y: 50)
                }
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Subviews

    private var braindumpCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Illustration in top-right
            HStack {
                Spacer()
                Image("calm_braindump")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            }
            .padding(.bottom, 8)

            // Title
            Text("Braindump")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            // Description
            Text("Get the noise out of your head. Write it down here to clear your mind instantly")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(2)
                .padding(.top, 4)

            // Arrow button
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.25))
                        .frame(width: 28, height: 28)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(
                colors: [AppTheme.amber, AppTheme.orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppTheme.amber.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    private var relaxationToolsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Relaxation Tools")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.warmTextPrimary)

            LazyVGrid(columns: columns, spacing: 16) {
                Button { showBreathe = true } label: {
                    toolCard(tool: tools[0])
                }
                .buttonStyle(.plain)

                Button { showJPMR = true } label: {
                    toolCard(tool: tools[1])
                }
                .buttonStyle(.plain)

                Button { showASMR = true } label: {
                    toolCard(tool: tools[2])
                }
                .buttonStyle(.plain)

                Button { showDeepFocus = true } label: {
                    toolCard(tool: tools[3])
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toolCard(tool: ToolInfo) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Illustration area
            HStack {
                Spacer()
                Image(tool.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            }
            .padding(.bottom, 8)

            Spacer()

            // Title
            Text(tool.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)

            // Subtitle
            Text(tool.subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .padding(.top, 1)

            // Detail
            Text(tool.detail)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 4)

            // Plus button
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.25))
                        .frame(width: 28, height: 28)
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .frame(height: 190)
        .background(
            LinearGradient(
                colors: [tool.color, tool.gradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: tool.color.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    private var dailyTipRow: some View {
        HStack(spacing: 14) {
            Image("calm_dailytip")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Tip")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.warmTextPrimary)

                Text("Focus on exhale helps maintain stress")
                    .font(.caption)
                    .foregroundStyle(AppTheme.warmTextSecondary)
            }

            Spacer()
        }
        .padding()
        .glassCard()
    }
}

#Preview {
    CalmCentreView()
        .environment(CalmCentreStore.shared)
}
