import SwiftUI

extension Color {
    // MARK: - Brand Accent
    /// Primary brand accent (clay/terracotta). Light: #C2613D, Dark: #E08A63.
    static let solsticeAccent = Color(light: Color(hex: "#C2613D"), dark: Color(hex: "#E08A63"))

    // MARK: - Cycle Phase Colors
    /// Logged period days. Light: #C0392B, Dark: #E76A5B.
    static let solsticePeriod = Color(light: Color(hex: "#C0392B"), dark: Color(hex: "#E76A5B"))

    /// Fertile window days (teal). Light: #2E8B8B, Dark: #4FB3B3.
    static let solsticeFertile = Color(light: Color(hex: "#2E8B8B"), dark: Color(hex: "#4FB3B3"))

    /// Ovulation day (amber). Light: #C9882B, Dark: #E0A84A.
    static let solsticeOvulation = Color(light: Color(hex: "#C9882B"), dark: Color(hex: "#E0A84A"))

    // MARK: - Backgrounds
    /// App canvas. Light: #FAF7F3, Dark: #181512.
    static let solsticeBackground = Color(light: Color(hex: "#FAF7F3"), dark: Color(hex: "#181512"))

    /// Cards and sheets raised above canvas. Light: #FFFFFF, Dark: #221E1A.
    static let solsticeSurface = Color(light: Color(hex: "#FFFFFF"), dark: Color(hex: "#221E1A"))

    /// Grouped row fills, input fields. Light: #F2EDE7, Dark: #2C2722.
    static let solsticeSurfaceSecondary = Color(light: Color(hex: "#F2EDE7"), dark: Color(hex: "#2C2722"))

    /// Hairline dividers. Light: #E4DDD4, Dark: #393229.
    static let solsticeSeparator = Color(light: Color(hex: "#E4DDD4"), dark: Color(hex: "#393229"))

    // MARK: - Text
    /// Body and headings. Light: #2A2521, Dark: #F4EFE9.
    static let solsticeTextPrimary = Color(light: Color(hex: "#2A2521"), dark: Color(hex: "#F4EFE9"))

    /// Captions and secondary labels. Light: #6B6258, Dark: #B7ADA0.
    static let solsticeTextSecondary = Color(light: Color(hex: "#6B6258"), dark: Color(hex: "#B7ADA0"))

    /// Placeholder and disabled text. Light: #9A9085, Dark: #7E756A.
    static let solsticeTextTertiary = Color(light: Color(hex: "#9A9085"), dark: Color(hex: "#7E756A"))

    // MARK: - Soft Washes
    /// Tinted fill behind accent icons. Light: #F3E2D8, Dark: #3A2A20.
    static let solsticeAccentSoft = Color(light: Color(hex: "#F3E2D8"), dark: Color(hex: "#3A2A20"))

    /// Period fill wash. Light: #F6DCD8, Dark: #3A201C.
    static let solsticePeriodSoft = Color(light: Color(hex: "#F6DCD8"), dark: Color(hex: "#3A201C"))

    /// Fertile window wash. Light: #D8ECEC, Dark: #16302F.
    static let solsticeFertileSoft = Color(light: Color(hex: "#D8ECEC"), dark: Color(hex: "#16302F"))

    /// Ovulation wash. Light: #F6E9CF, Dark: #332710.
    static let solsticeOvulationSoft = Color(light: Color(hex: "#F6E9CF"), dark: Color(hex: "#332710"))

    // MARK: - Semantic
    /// Privacy/lock accent (calm slate-blue). Light: #3E6B8B, Dark: #6FA2C4.
    static let solsticeLockTint = Color(light: Color(hex: "#3E6B8B"), dark: Color(hex: "#6FA2C4"))

    /// Success confirmations. Light: #3C7D5A, Dark: #5FB585.
    static let solsticeSuccess = Color(light: Color(hex: "#3C7D5A"), dark: Color(hex: "#5FB585"))

    /// Warning / caution states. Light: #B26A1C, Dark: #D08A3A.
    static let solsticeWarning = Color(light: Color(hex: "#B26A1C"), dark: Color(hex: "#D08A3A"))

    /// Predicted (not-yet-logged) outlines. Light: #B9AFA3, Dark: #6C6359.
    static let solsticePredicted = Color(light: Color(hex: "#B9AFA3"), dark: Color(hex: "#6C6359"))

    /// Primary action pressed state. Light: #A64F2F, Dark: #C2613D.
    static let solsticeAccentPressed = Color(light: Color(hex: "#A64F2F"), dark: Color(hex: "#C2613D"))
}

// MARK: - Color Initializers

extension Color {
    /// Creates an adaptive color with separate light and dark mode variants.
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }

    /// Creates a Color from a hex string (e.g. "#C2613D" or "C2613D").
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let red, green, blue, alpha: UInt64
        switch hex.count {
        case 6:
            (red, green, blue, alpha) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8:
            (red, green, blue, alpha) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (red, green, blue, alpha) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}
