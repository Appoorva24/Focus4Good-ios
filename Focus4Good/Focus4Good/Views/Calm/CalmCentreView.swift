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
            .background(AppTheme.appGradient.ignoresSafeArea())
            .navigationTitle("Calm Centre")
            .navigationDestination(isPresented: $showBraindump) { BraindumpHomeView() }
            .navigationDestination(isPresented: $showBreathe) { BreatheSessionView() }
            .navigationDestination(isPresented: $showJPMR) { JPMRSessionView() }
            .navigationDestination(isPresented: $showASMR) { SensorySootheView() }
            .navigationDestination(isPresented: $showDeepFocus) { DeepFocusBrowseView() }
        }
    }

    // MARK: - Subviews

    private var braindumpCard: some View {
        Image("BRAINDUMPCARD")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Braindump")
                        .font(.system(.title2, design: .default, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text("Get the noise out\nof your head.")
                        .font(.system(.caption2, design: .default, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    
                    Spacer().frame(height: 2)
                    
                    HStack(spacing: 4) {
                        Text("Start Dumping")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10))
                    }
                    .font(.system(.caption, design: .default, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .clipShape(Capsule())
                }
                .padding(.leading, 20)
                .padding(.trailing, 160) // Increase right padding to give image more breathing room
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var relaxationToolsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Relaxation Tools")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            LazyVGrid(columns: columns, spacing: 16) {
                Button { showBreathe = true } label: {
                    VStack(spacing: 0) {
                        Image("breathe")
                            .resizable()
                            .scaledToFill()
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 90, maxHeight: 90)
                            .clipped()
                        
                        VStack(alignment: .center) {
                            Text("4-7-8 Breathing Technique")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.9)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(height: 50)
                        .background(Color(.secondarySystemGroupedBackground))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)

                Button { showJPMR = true } label: {
                    VStack(spacing: 0) {
                        Image("JPMR")
                            .resizable()
                            .scaledToFill()
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 90, maxHeight: 90)
                            .clipped()
                        
                        VStack(alignment: .center) {
                            Text("Jacobson's Progressive Muscle Relaxation")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(height: 50)
                        .background(Color(.secondarySystemGroupedBackground))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)

                Button { showASMR = true } label: {
                    VStack(spacing: 0) {
                        Image("ASMR")
                            .resizable()
                            .scaledToFill()
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 105, maxHeight: 105)
                            .clipped()
                        
                        VStack(alignment: .center) {
                            Text("ASMR Sounds")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.9)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(height: 35)
                        .background(Color(.secondarySystemGroupedBackground))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)

                Button { showDeepFocus = true } label: {
                    VStack(spacing: 0) {
                        Image("DEEPFOCUS")
                            .resizable()
                            .scaledToFill()
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 105, maxHeight: 105)
                            .clipped()
                        
                        VStack(alignment: .center) {
                            Text("Deep Focus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.9)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(height: 35)
                        .background(Color(.secondarySystemGroupedBackground))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
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
