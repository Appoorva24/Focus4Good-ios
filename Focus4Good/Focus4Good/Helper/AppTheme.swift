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

    // MARK: - Adaptive Progress Screen Colors

    /// Page background gradient colors (top → middle → bottom)
    static let pageBgTop = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(hex6: 0x1C1C1E) : UIColor(hex6: 0xFFF5EB)
    })
    static let pageBgMid = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(hex6: 0x1A1A1C) : UIColor(hex6: 0xFFF0E0)
    })
    static let pageBgBot = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(hex6: 0x171719) : UIColor(hex6: 0xFFEBD4)
    })

    /// Card gradient end tint
    static let cardGradientEnd = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(hex6: 0x2C2520) : UIColor(hex6: 0xFFF5EB)
    })

    /// Warm primary text (headings inside cards)
    static let warmTextPrimary = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(hex6: 0xF5E6D3) : UIColor(hex6: 0x5C4A32)
    })

    /// Warm secondary text (subtitles, captions)
    static let warmTextSecondary = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(hex6: 0xC4A882) : UIColor(hex6: 0x9E8B73)
    })

    /// Card label text (e.g. "Tasks Completed", "Time Spent")
    static let cardLabel = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(hex6: 0xD4BC9A) : UIColor(hex6: 0x8B7355)
    })

    /// Thought card gradient
    static let thoughtCardStart = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(hex6: 0x2A2218) : UIColor(hex6: 0xFFF8F0)
    })
    static let thoughtCardEnd = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(hex6: 0x33291D) : UIColor(hex6: 0xFFEDD8)
    })
}

// MARK: - UIColor Hex Helper

private extension UIColor {
    convenience init(hex6: UInt32) {
        self.init(
            red:   CGFloat((hex6 >> 16) & 0xFF) / 255,
            green: CGFloat((hex6 >> 8)  & 0xFF) / 255,
            blue:  CGFloat( hex6        & 0xFF) / 255,
            alpha: 1
        )
    }
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
