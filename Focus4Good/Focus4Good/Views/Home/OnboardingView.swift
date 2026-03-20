import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $currentPage) {
                ForEach(0..<DummyData.onboardingPages.count, id: \.self) { index in
                    OnboardingPageView(
                        page: DummyData.onboardingPages[index],
                        pageIndex: index,
                        totalPages: DummyData.onboardingPages.count,
                        currentPage: $currentPage,
                        hasSeenOnboarding: $hasSeenOnboarding
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            Button("Skip") {
                hasSeenOnboarding = true
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(Capsule().fill(AppTheme.orange))
            .padding(.top, 60)
            .padding(.trailing, 20)
        }
    }
}

struct OnboardingPageView: View {
    let page: (title: String, subtitle: String, imageName: String)
    let pageIndex: Int
    let totalPages: Int
    @Binding var currentPage: Int
    @Binding var hasSeenOnboarding: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            RoundedRectangle(cornerRadius: 28)
                .fill(Color(hex: "FFF3E8"))
                .frame(width: 290, height: 290)
                .overlay {
                    Image(page.imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(24)
                }
                .padding(.bottom, 52)

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(page.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 36)
            }

            Spacer()

            pageIndicator
                .padding(.bottom, 28)

            Button(action: handleNext) {
                Text(pageIndex == totalPages - 1 ? "Get Started" : "Next")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Capsule().fill(AppTheme.orange))
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 52)
        }
        .background(Color.white)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == pageIndex ? AppTheme.orange : Color(.systemGray4))
                    .frame(width: index == pageIndex ? 28 : 8, height: 8)
                    .animation(.spring(duration: 0.3), value: pageIndex)
            }
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
