import SwiftUI

// MARK: - SplashView
// Shows the Focus4Good logo + app name with a smooth scale-fade animation.
// Calls `onFinished` after the animation completes so the parent can
// transition to the next screen.

struct SplashView: View {
    let onFinished: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var bounce: Bool = false

    var body: some View {
        ZStack {
            // Background — White as requested
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // ── Logo ─────────────────────────────────────────
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .scaleEffect(bounce ? 1.05 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                        value: bounce
                    )

                // ── App name ─────────────────────────────────────
                VStack(spacing: 6) {
                    Text("Focus4Good")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "FF8C00")) // Orange to match the logo

                    Text("Focus. Grow. Give Back.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.gray)
                        .kerning(0.5)
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            // Initial scale & fade-in animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Start the gentle bounce animation after it appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                bounce = true
            }

            // Transition after logo animation finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onFinished()
            }
        }
    }
}
