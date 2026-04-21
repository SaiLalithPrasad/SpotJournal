import Testing
import SwiftUI
@testable import SpotJournal

struct ThemeTests {

    // MARK: - Color hex init

    @Test func colorHexBlack() {
        let color = Color(hex: 0x000000)
        // Verify it creates without crashing
        #expect(color.description.isEmpty == false)
    }

    @Test func colorHexWhite() {
        let color = Color(hex: 0xFFFFFF)
        #expect(color.description.isEmpty == false)
    }

    @Test func colorHexRed() {
        let color = Color(hex: 0xFF0000)
        #expect(color.description.isEmpty == false)
    }

    // MARK: - JournalTheme light vs dark

    @Test func lightThemeIsNotDark() {
        let theme = JournalTheme(isDark: false)
        #expect(theme.isDark == false)
    }

    @Test func darkThemeIsDark() {
        let theme = JournalTheme(isDark: true)
        #expect(theme.isDark == true)
    }

    @Test func lightAndDarkThemesHaveDifferentBackgrounds() {
        let light = JournalTheme(isDark: false)
        let dark = JournalTheme(isDark: true)
        // The backgrounds should differ
        #expect(light.bg != dark.bg)
    }

    @Test func themeHasAllRequiredProperties() {
        let theme = JournalTheme(isDark: false)
        // Verify all color properties exist and are valid by accessing them
        let _ = theme.bg
        let _ = theme.bgAlt
        let _ = theme.surface
        let _ = theme.surfaceRaised
        let _ = theme.surfaceSunken
        let _ = theme.paperBg
        let _ = theme.fg1
        let _ = theme.fg2
        let _ = theme.fg3
        let _ = theme.fg4
        let _ = theme.fgOnAccent
        let _ = theme.accent
        let _ = theme.accentPress
        let _ = theme.accentSoft
        let _ = theme.border1
        let _ = theme.border2
        let _ = theme.ink1
        let _ = theme.ink2
        let _ = theme.ink3
        let _ = theme.danger
        let _ = theme.scrim
        let _ = theme.iconChipBg
        let _ = theme.iconChipBorder
    }

    @Test func darkThemeHasAllRequiredProperties() {
        let theme = JournalTheme(isDark: true)
        let _ = theme.bg
        let _ = theme.bgAlt
        let _ = theme.surface
        let _ = theme.surfaceRaised
        let _ = theme.surfaceSunken
        let _ = theme.paperBg
        let _ = theme.fg1
        let _ = theme.fg2
        let _ = theme.fg3
        let _ = theme.fg4
        let _ = theme.fgOnAccent
        let _ = theme.accent
        let _ = theme.accentPress
        let _ = theme.accentSoft
        let _ = theme.border1
        let _ = theme.border2
        let _ = theme.ink1
        let _ = theme.ink2
        let _ = theme.ink3
        let _ = theme.danger
        let _ = theme.scrim
        let _ = theme.iconChipBg
        let _ = theme.iconChipBorder
    }
}
