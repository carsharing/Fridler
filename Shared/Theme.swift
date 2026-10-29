import SwiftUI

/// Flat cartoon look shared by the app and the widget: flat fills, thick dark
/// outlines and hard (unblurred) offset shadows.
enum Palette {
    static let ink = Color(hex: 0x23202B)
    static let paper = Color(hex: 0xFFFDF7)
    static let paperShade = Color(hex: 0xE6DFCD)
    static let marker = Color(hex: 0x1E1E24)
    static let markerRed = Color(hex: 0xE5484D)
    static let shadow = Color.black.opacity(0.22)
    static let cardShadow = Color(hex: 0x23202B).opacity(0.9)
}

enum FridgeColor: String, Codable, CaseIterable, Identifiable {
    case white, steel, mint, butter, cherry, midnight

    var id: String { rawValue }

    var name: String {
        switch self {
        case .white: "Classic white"
        case .steel: "Brushed steel"
        case .mint: "Retro mint"
        case .butter: "Butter cream"
        case .cherry: "Cherry red"
        case .midnight: "Midnight"
        }
    }

    var door: Color {
        switch self {
        case .white: Color(hex: 0xEEF0F2)
        case .steel: Color(hex: 0xC4CBD3)
        case .mint: Color(hex: 0xA6DEC6)
        case .butter: Color(hex: 0xF5E2A8)
        case .cherry: Color(hex: 0xE5484D)
        case .midnight: Color(hex: 0x2E3142)
        }
    }

    var shine: Color {
        switch self {
        case .white: Color.white.opacity(0.9)
        case .steel: Color.white.opacity(0.45)
        case .mint, .butter: Color.white.opacity(0.4)
        case .cherry: Color.white.opacity(0.22)
        case .midnight: Color.white.opacity(0.07)
        }
    }

    /// Text sitting directly on the door needs to flip to light on dark doors.
    var isDark: Bool { self == .cherry || self == .midnight }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
