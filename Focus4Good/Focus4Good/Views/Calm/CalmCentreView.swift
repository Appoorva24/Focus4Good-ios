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
        let title: String
        let subtitle: String
        let color: Color
    }

    private let tools: [ToolInfo] = [
        ToolInfo(icon: "wind", title: "Breathe", subtitle: "4-7-8 Technique", color: Color(hex: "0EA5E9")),
        ToolInfo(icon: "figure.walk", title: "Unwind Body", subtitle: "JPMR Muscle Relax", color: Color(hex: "8B5CF6")),
        ToolInfo(icon: "speaker.wave.3", title: "Sensory Soothe", subtitle: "ASMR Sounds", color: Color(hex: "EC4899")),
        ToolInfo(icon: "leaf", title: "Deep Focus", subtitle: "Guided Meditation", color: Color(hex: "22C55E")),
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(AppTheme.amberLight)
                        .frame(width: 44, height: 44)
                    Image(systemName: "pencil.and.list.clipboard")
                        .font(.title3)
                        .foregroundStyle(AppTheme.amber)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.warmTextSecondary)
            }

            Text("Braindump")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.warmTextPrimary)

            Text("Get the noise out of your head. Write it down here to clear your mind instantly")
                .font(.subheadline)
                .foregroundStyle(AppTheme.warmTextSecondary)
        }
        .padding()
        .glassCard()
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
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(tool.color.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: tool.icon)
                    .font(.title2)
                    .foregroundStyle(tool.color)
            }

            Text(tool.title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.warmTextPrimary)

            Text(tool.subtitle)
                .font(.caption)
                .foregroundStyle(AppTheme.warmTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .glassCard()
    }

    private var dailyTipRow: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.amberLight)
                    .frame(width: 44, height: 44)
                Image(systemName: "lightbulb.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.amber)
            }

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
