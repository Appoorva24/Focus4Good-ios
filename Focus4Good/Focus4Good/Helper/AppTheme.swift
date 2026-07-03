import SwiftUI

// MARK: - App Theme

enum AppTheme {
    /// Brand accent — #FBB17C
    static let orange      = Color(hex: "FBB17C")
    /// 15 % tint of the accent, used for icon backgrounds and subtle fills
    static let accentLight = Color(hex: "FBB17C").opacity(0.15)
    /// Standard card background (adapts to light / dark mode)
    static let cardBg      = Color(.systemBackground)
    /// Subtle drop-shadow colour
    static let shadow      = Color.black.opacity(0.05)
    /// Default corner radius for cards
    static let cornerRadius: CGFloat = 16

    static let textPrimary   = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    
    /// Standard app-wide gradient using the brand accent
    static let appGradient = LinearGradient(
        colors: [
            Color(hex: "FFD5B3"), // Softer, lighter orange at the top
            Color(hex: "FFF2E6")  // Very pale cream orange at the bottom
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255,
                            (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
