import SwiftUI

struct JournalTheme {
    let isDark: Bool

    var bg: Color { isDark ? Color(hex: 0x1F1E1D) : Color(hex: 0xFAF9F5) }
    var bgAlt: Color { isDark ? Color(hex: 0x26251F) : Color(hex: 0xF5F4EE) }
    var surface: Color { isDark ? Color(hex: 0x2A2928) : .white }
    var surfaceRaised: Color { isDark ? Color(hex: 0x30302E) : .white }
    var surfaceSunken: Color { isDark ? Color(hex: 0x161615) : Color(hex: 0xF0EEE6) }
    var paperBg: Color { isDark ? Color(hex: 0x25211C) : Color(hex: 0xF5EFE0) }

    var fg1: Color { isDark ? Color(hex: 0xF0EEE6) : Color(hex: 0x141413) }
    var fg2: Color { isDark ? Color(hex: 0xC9C6BC) : Color(hex: 0x3D3D3A) }
    var fg3: Color { isDark ? Color(hex: 0x8F8D84) : Color(hex: 0x6B6A63) }
    var fg4: Color { isDark ? Color(hex: 0x5E5C56) : Color(hex: 0x9A978C) }
    var fgOnAccent: Color { isDark ? Color(hex: 0x1F1E1D) : .white }

    var accent: Color { isDark ? Color(hex: 0xE08A6C) : Color(hex: 0xD97757) }
    var accentPress: Color { isDark ? Color(hex: 0xD97757) : Color(hex: 0xB85A3D) }
    var accentSoft: Color { isDark ? Color(hex: 0x3A2E27) : Color(hex: 0xF5E6DF) }

    var border1: Color { isDark ? Color(hex: 0x3A3937) : Color(hex: 0xE8E5DA) }
    var border2: Color { isDark ? Color(hex: 0x4A4845) : Color(hex: 0xD8D4C8) }

    var ink1: Color { isDark ? Color(hex: 0xEBE5D4) : Color(hex: 0x2A241C) }
    var ink2: Color { isDark ? Color(hex: 0xB5AC95) : Color(hex: 0x5A4E3C) }
    var ink3: Color { isDark ? Color(hex: 0x7D7460) : Color(hex: 0x8A7E6A) }

    var danger: Color { isDark ? Color(hex: 0xE05C5C) : Color(hex: 0xC9413F) }

    var scrim: Color { isDark ? .black.opacity(0.6) : Color(hex: 0x141413).opacity(0.44) }

    var iconChipBg: Color {
        isDark ? Color(hex: 0x322C26).opacity(0.7) : Color(hex: 0xFAF7F0).opacity(0.72)
    }
    var iconChipBorder: Color {
        isDark ? Color(hex: 0xF0E1BE).opacity(0.10) : Color(hex: 0x8C6E3C).opacity(0.14)
    }
}

extension Color {
    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
