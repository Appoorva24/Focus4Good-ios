import SwiftUI

struct BreatheIntroView: View {

    @State private var showSession = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                headerSection
                stepsSection
                benefitsSection
                beginButton
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationDestination(isPresented: $showSession) { BreatheSessionView() }
        .navigationTitle("Breathe")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 14) {
            Image(systemName: "wind")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)

            Text("4-7-8 Breathing")
                .font(.title2)
                .fontWeight(.bold)

            Text("A simple technique that calms your nervous system in minutes. Breathe in, hold, and exhale at a set rhythm.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How It Works")
                .font(.headline)

            VStack(spacing: 0) {
                stepRow(title: "Breathe In", duration: "4 seconds", icon: "arrow.down.circle.fill")
                Divider().padding(.leading, 60)
                stepRow(title: "Hold", duration: "7 seconds", icon: "pause.circle.fill")
                Divider().padding(.leading, 60)
                stepRow(title: "Breathe Out", duration: "8 seconds", icon: "arrow.up.circle.fill")
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemBackground))
            )
        }
    }

    private func stepRow(title: String, duration: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(duration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Benefits")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                benefitRow("Reduces anxiety and stress")
                benefitRow("Helps you fall asleep faster")
                benefitRow("Lowers heart rate")
                benefitRow("Improves focus and concentration")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemBackground))
            )
        }
    }

    private func benefitRow(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.accentColor)
                .font(.subheadline)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var beginButton: some View {
        Button { showSession = true } label: {
            Text("Begin")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Capsule().fill(Color.accentColor))
        }
    }
}

#Preview {
    NavigationStack {
        BreatheIntroView()
    }
}
