import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private let pages = DummyData.onboardingPages

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Navigation bar ───────────────────────────────
                HStack {
                    // Back button (hidden on first page)
                    Button {
                        withAnimation { currentPage -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color(.systemGray6))
                            )
                    }
                    .opacity(currentPage > 0 ? 1 : 0)
                    .disabled(currentPage == 0)

                    Spacer()

                    // Skip button
                    Button("Skip") {
                        hasSeenOnboarding = true
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(AppTheme.orange))
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // ── Page content ─────────────────────────────────
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageContent(
                            page: pages[index],
                            pageIndex: index,
                            totalPages: pages.count,
                            currentPage: $currentPage,
                            hasSeenOnboarding: $hasSeenOnboarding
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
    }
}

// MARK: - Single page content

private struct OnboardingPageContent: View {
    let page: (title: String, subtitle: String, imageName: String)
    let pageIndex: Int
    let totalPages: Int
    @Binding var currentPage: Int
    @Binding var hasSeenOnboarding: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 20)

            // ── Image area ───────────────────────────────────
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "FFF3E8"))

                Image(page.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .padding(12)
            }
            .frame(width: UIScreen.main.bounds.width - 120)
            .aspectRatio(1.05, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            Spacer().frame(height: 32)

            // ── Text area ────────────────────────────────────
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(page.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }

            Spacer()

            // ── Dots ─────────────────────────────────────────
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == pageIndex
                              ? AppTheme.textPrimary
                              : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 28)

            // ── Next / Get Started button ────────────────────
            Button(action: handleNext) {
                Text(pageIndex == totalPages - 1 ? "Get Started" : "Next")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Capsule().fill(AppTheme.orange.opacity(0.45)))
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
    }

    private func handleNext() {
        if pageIndex == totalPages - 1 {
            hasSeenOnboarding = true
        } else {
            withAnimation { currentPage += 1 }
        }
    }
}
