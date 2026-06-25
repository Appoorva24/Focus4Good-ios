import SwiftUI

struct OnboardingView: View {
    // Called by Focus4GoodApp when the user finishes/skips onboarding
    let onComplete: () -> Void

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private let pages = DummyData.onboardingPages

    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Navigation bar ───────────────────────────────
                HStack {
                    // Back button
                    Button {
                        if currentPage > 0 {
                            withAnimation { currentPage -= 1 }
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color(.systemGray6))
                                    .opacity(currentPage > 0 ? 1 : 0)
                            )
                    }
                    .disabled(currentPage == 0)
                    .opacity(currentPage > 0 ? 1 : 0)

                    Spacer()

                    Button("Skip") {
                        markSeenAndComplete()
                    }
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // ── Page content ─────────────────────────────────
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageContent(
                            page: pages[index],
                            pageIndex: index,
                            totalPages: pages.count,
                            currentPage: $currentPage,
                            onFinish: markSeenAndComplete
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
    }

    private func markSeenAndComplete() {
        hasSeenOnboarding = true
        onComplete()
    }
}

// MARK: - Single page content

private struct OnboardingPageContent: View {
    let page: (title: String, subtitle: String, imageName: String)
    let pageIndex: Int
    let totalPages: Int
    @Binding var currentPage: Int
    let onFinish: () -> Void

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                Spacer(minLength: 16)

                // ── Image area ───────────────────────────────────
                Image(page.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 280, height: 280)
                    .clipped()

                Spacer(minLength: 32)

                // ── Text area ────────────────────────────────────
                VStack(spacing: 14) {
                    Text(page.title)
                        .font(.system(size: 26, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)

                    Text(page.subtitle)
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 36)
                }

                Spacer(minLength: 28)

                // ── Dots ─────────────────────────────────────────
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == pageIndex
                                  ? AppTheme.textPrimary
                                  : Color(.systemGray3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 32)

                // ── Next / Get Started button ────────────────────
                Button(action: handleNext) {
                    Text(pageIndex == totalPages - 1 ? "Get Started" : "Next")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Capsule().fill(AppTheme.orange))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 36)
            }
        }
    }

    private func handleNext() {
        if pageIndex == totalPages - 1 {
            onFinish()
        } else {
            withAnimation { currentPage += 1 }
        }
    }
}
