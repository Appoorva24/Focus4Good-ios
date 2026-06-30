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
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
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
        ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
            
            ZStack(alignment: .trailing) {
                Image("braindump_illustration")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 160)
                    .offset(x: 20, y: 5)
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Braindump")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Text("Get the noise out of your head.\nWrite it down here to clear\nyour mind instantly.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.trailing, 110)
                    
                    Spacer()
                }
                .padding(.vertical, 32)
                .padding(.horizontal, 20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var relaxationToolsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Relaxation Tools")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            LazyVGrid(columns: columns, spacing: 16) {
                Button { showBreathe = true } label: {
                    toolCard(icon: "wind", title: "Breathe", subtitle: "4-7-8 Technique", color: .orange)
                }
                .buttonStyle(.plain)

                Button { showJPMR = true } label: {
                    toolCard(icon: "figure.walk", title: "Unwind Body", subtitle: "JPMR Muscle Relax", color: .green)
                }
                .buttonStyle(.plain)

                Button { showASMR = true } label: {
                    toolCard(icon: "speaker.wave.3", title: "Sensory Soothe", subtitle: "ASMR Sounds", color: .purple)
                }
                .buttonStyle(.plain)

                Button { showDeepFocus = true } label: {
                    toolCard(icon: "leaf", title: "Deep Focus", subtitle: "Guided Meditation", color: .blue)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toolCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(color.opacity(0.12)))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color(.tertiaryLabel))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }

    private var dailyTipRow: some View {
        HStack(spacing: 16) {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundStyle(Color.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Tip")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text("Focus on exhale helps maintain stress.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

#Preview {
    CalmCentreView()
        .environment(CalmCentreStore.shared)
}
