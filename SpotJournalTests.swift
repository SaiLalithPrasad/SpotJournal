import XCTest
import SwiftUI
import Foundation
import SwiftData
import UIKit
@testable import SpotJournal

// MARK: - Theme Tests

final class ThemeTests: XCTestCase {

    // MARK: - Color hex init

    func testColorHexBlack() {
        let color = Color(hex: 0x000000)
        XCTAssertFalse(color.description.isEmpty)
    }

    func testColorHexWhite() {
        let color = Color(hex: 0xFFFFFF)
        XCTAssertFalse(color.description.isEmpty)
    }

    func testColorHexRed() {
        let color = Color(hex: 0xFF0000)
        XCTAssertFalse(color.description.isEmpty)
    }

    // MARK: - JournalTheme light vs dark

    func testLightThemeIsNotDark() {
        let theme = JournalTheme(isDark: false, useOLED: false)
        XCTAssertFalse(theme.isDark)
    }

    func testDarkThemeIsDark() {
        let theme = JournalTheme(isDark: true, useOLED: false)
        XCTAssertTrue(theme.isDark)
    }

    func testLightAndDarkThemesHaveDifferentBackgrounds() {
        let light = JournalTheme(isDark: false, useOLED: false)
        let dark = JournalTheme(isDark: true, useOLED: false)
        XCTAssertNotEqual(light.bg, dark.bg)
    }
    
    func testOledDarkModeUsesTrueBlack() {
        let regularDark = JournalTheme(isDark: true, useOLED: false)
        let oledDark = JournalTheme(isDark: true, useOLED: true)
        XCTAssertEqual(oledDark.bg, .black)
        XCTAssertNotEqual(regularDark.bg, .black)
    }
    
    func testOledModeOnlyAppliesInDarkMode() {
        let lightWithOLED = JournalTheme(isDark: false, useOLED: true)
        let lightWithoutOLED = JournalTheme(isDark: false, useOLED: false)
        XCTAssertEqual(lightWithOLED.bg, lightWithoutOLED.bg)
    }

    func testThemeHasAllRequiredProperties() {
        let theme = JournalTheme(isDark: false, useOLED: false)
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

    func testDarkThemeHasAllRequiredProperties() {
        let theme = JournalTheme(isDark: true, useOLED: false)
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
    
    func testOledThemeHasAllRequiredProperties() {
        let theme = JournalTheme(isDark: true, useOLED: true)
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

// MARK: - Models Tests

final class ModelsTests: XCTestCase {

    // MARK: - JournalEntry.generateId

    func testGenerateIdHasCorrectPrefix() {
        let id = JournalEntry.generateId()
        XCTAssertTrue(id.hasPrefix("e-"))
    }

    func testGenerateIdContainsTimestamp() {
        let before = Int(Date().timeIntervalSince1970)
        let id = JournalEntry.generateId()
        let after = Int(Date().timeIntervalSince1970)

        let parts = id.split(separator: "-")
        XCTAssertEqual(parts.count, 3)
        let timestamp = Int(parts[1])!
        XCTAssertTrue(timestamp >= before && timestamp <= after)
    }

    func testGenerateIdHasRandomSuffix() {
        let id = JournalEntry.generateId()
        let parts = id.split(separator: "-")
        let suffix = Int(parts[2])!
        XCTAssertTrue(suffix >= 1000 && suffix <= 9999)
    }

    func testGenerateIdProducesUniqueValues() {
        let ids = (0..<20).map { _ in JournalEntry.generateId() }
        let unique = Set(ids)
        XCTAssertEqual(unique.count, ids.count)
    }

    // MARK: - CaptionFont

    @Test("Caption font raw values")
    func captionFontRawValues() {
        #expect(CaptionFont.serif.rawValue == "serif")
        #expect(CaptionFont.sans.rawValue == "sans")
        #expect(CaptionFont.hand.rawValue == "hand")
    }

    @Test("Caption font labels")
    func captionFontLabels() {
        #expect(CaptionFont.serif.label == "Typeset")
        #expect(CaptionFont.sans.label == "Plain")
        #expect(CaptionFont.hand.label == "Written")
    }

    @Test("Caption font sample is shared")
    func captionFontSampleIsShared() {
        for font in CaptionFont.allCases {
            #expect(font.sample == "The morning was quiet.")
        }
    }

    @Test("Caption font case iterable count")
    func captionFontCaseIterableCount() {
        #expect(CaptionFont.allCases.count == 3)
    }

    // MARK: - LayoutStyle

    @Test("Layout style raw values")
    func layoutStyleRawValues() {
        #expect(LayoutStyle.classic.rawValue == "classic")
        #expect(LayoutStyle.offset.rawValue == "offset")
        #expect(LayoutStyle.split.rawValue == "split")
    }

    @Test("Layout style labels")
    func layoutStyleLabels() {
        #expect(LayoutStyle.classic.label == "Classic")
        #expect(LayoutStyle.offset.label == "Offset")
        #expect(LayoutStyle.split.label == "Split")
    }

    @Test("Layout style blurbs are non-empty")
    func layoutStyleBlurbsAreNonEmpty() {
        for style in LayoutStyle.allCases {
            #expect(!style.blurb.isEmpty)
        }
    }

    // MARK: - PhotoKey

    @Test("Photo key cases")
    func photoKeyCases() {
        #expect(PhotoKey.allCases.count == 4)
        #expect(PhotoKey(rawValue: "window") == .window)
        #expect(PhotoKey(rawValue: "coffee") == .coffee)
        #expect(PhotoKey(rawValue: "trail") == .trail)
        #expect(PhotoKey(rawValue: "plate") == .plate)
        #expect(PhotoKey(rawValue: "invalid") == nil)
    }

    // MARK: - JournalEntry

    @Test("Placeholder entry properties")
    func placeholderEntryProperties() {
        let entry = JournalEntry(id: "test-1", photoKey: .coffee,
                                 caption: "Hello", date: Date(), place: "NYC")
        #expect(entry.isPlaceholder == true)
        #expect(entry.photoKey == .coffee)
        #expect(entry.photoKeyRaw == "coffee")
        #expect(entry.photoFileName == nil)
        #expect(entry.caption == "Hello")
        #expect(entry.place == "NYC")
        #expect(entry.importedAt == nil)
    }

    @Test("File entry properties")
    func fileEntryProperties() {
        let now = Date()
        let entry = JournalEntry(id: "test-2", photoFileName: "IMG_001.jpg",
                                 caption: "Test", date: now, place: "LA", importedAt: now)
        #expect(entry.isPlaceholder == false)
        #expect(entry.photoKey == nil)
        #expect(entry.photoFileName == "IMG_001.jpg")
        #expect(entry.importedAt != nil)
    }

    @Test("Photo source placeholder")
    func photoSourcePlaceholder() {
        let entry = JournalEntry(id: "ps-1", photoKey: .trail,
                                 caption: "", date: Date(), place: "")
        if case .placeholder(let key) = entry.photoSource {
            #expect(key == .trail)
        } else {
            Issue.record("Expected placeholder source")
        }
    }

    @Test("Photo source file")
    func photoSourceFile() {
        let entry = JournalEntry(id: "ps-2", photoFileName: "test.jpg",
                                 caption: "", date: Date(), place: "")
        if case .file(let name) = entry.photoSource {
            #expect(name == "test.jpg")
        } else {
            Issue.record("Expected file source")
        }
    }

    // MARK: - Tag

    @Test("Tag default colors")
    func tagDefaultColors() {
        #expect(Tag.defaultColors.count == 8)
        #expect(Tag.defaultColors[0] == 0xD97757)
    }

    @Test("Tag init")
    func tagInit() {
        let tag = Tag(name: "Recipe", colorHex: 0xFF0000)
        #expect(tag.name == "Recipe")
        #expect(tag.colorHex == 0xFF0000)
        #expect(!tag.id.isEmpty)
    }

    // MARK: - Mood

    @Test("Mood init")
    func moodInit() {
        let mood = Mood(name: "Happy", emoji: "😊", colorHex: 0xE08A6C)
        #expect(mood.name == "Happy")
        #expect(mood.emoji == "😊")
        #expect(mood.colorHex == 0xE08A6C)
        #expect(!mood.id.isEmpty)
    }

    @Test("Mood default seeds cover all cases")
    func moodDefaultSeedsCoverAllCases() {
        let names = Mood.defaultSeeds.map(\.name)
        #expect(names.contains("Happy"))
        #expect(names.contains("Sad"))
        #expect(names.contains("Grumpy"))
        #expect(names.contains("Lessons to Learn"))
        for seed in Mood.defaultSeeds {
            #expect(!seed.emoji.isEmpty)
            #expect(seed.colorHex != 0)
        }
    }

    @Test("Mood default emojis non-empty")
    func moodDefaultEmojisNonEmpty() {
        #expect(Mood.defaultEmojis.count >= 8)
        for emoji in Mood.defaultEmojis {
            #expect(!emoji.isEmpty)
        }
    }

    // MARK: - Sample Data

    @Test("Make sample entries count")
    func makeSampleEntriesCount() {
        let entries = makeSampleEntries()
        #expect(entries.count == 7)
    }

    @Test("Sample entries have unique IDs")
    func sampleEntriesHaveUniqueIds() {
        let entries = makeSampleEntries()
        let ids = Set(entries.map(\.id))
        #expect(ids.count == entries.count)
    }

    // MARK: - AppState Tests

    @MainActor
    private func makeTestState() throws -> AppState {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: JournalEntry.self, Tag.self, Mood.self, configurations: config)
        let state = AppState()
        state.modelContext = ModelContext(container)
        return state
    }

    @Test @MainActor func deleteTagRemovesFromStore() throws {
        let state = try makeTestState()
        let tag = state.createTag(name: "Travel", colorHex: 0xFF0000)
        #expect(state.allTags.count == 1)
        state.deleteTag(tag)
        #expect(state.allTags.count == 0)
    }

    @Test @MainActor func deleteTagRemovesFromEntries() throws {
        let state = try makeTestState()
        let tag = state.createTag(name: "Food", colorHex: 0x00FF00)
        let entry = JournalEntry(id: "dt-1", photoKey: .coffee,
                                 caption: "Test", date: Date(), place: "")
        entry.tags = [tag]
        state.modelContext?.insert(entry)
        try state.modelContext?.save()

        #expect(entry.tags.count == 1)
        state.deleteTag(tag)
        #expect(entry.tags.count == 0)
        #expect(state.allTags.count == 0)
    }

    @Test @MainActor func deleteTagLeavesOtherTagsIntact() throws {
        let state = try makeTestState()
        let tag1 = state.createTag(name: "Travel", colorHex: 0xFF0000)
        let tag2 = state.createTag(name: "Food", colorHex: 0x00FF00)
        let entry = JournalEntry(id: "dt-2", photoKey: .trail,
                                 caption: "Test", date: Date(), place: "")
        entry.tags = [tag1, tag2]
        state.modelContext?.insert(entry)
        try state.modelContext?.save()

        state.deleteTag(tag1)
        #expect(state.allTags.count == 1)
        #expect(state.allTags.first?.name == "Food")
        #expect(entry.tags.count == 1)
        #expect(entry.tags.first?.name == "Food")
    }

    @Test @MainActor func createMoodPersists() throws {
        let state = try makeTestState()
        let mood = state.createMood(name: "Curious", emoji: "🤔", colorHex: 0x5A7EB5)
        #expect(state.allMoods.count == 1)
        #expect(state.allMoods.first?.id == mood.id)
    }

    @Test @MainActor func renameMoodUpdatesName() throws {
        let state = try makeTestState()
        let mood = state.createMood(name: "Happy", emoji: "😊", colorHex: 0xE08A6C)
        state.renameMood(mood, to: "Joyful")
        #expect(mood.name == "Joyful")
    }

    @Test @MainActor func renameMoodIgnoresEmptyName() throws {
        let state = try makeTestState()
        let mood = state.createMood(name: "Happy", emoji: "😊", colorHex: 0xE08A6C)
        state.renameMood(mood, to: "   ")
        #expect(mood.name == "Happy")
    }

    @Test @MainActor func updateMoodEmojiChanges() throws {
        let state = try makeTestState()
        let mood = state.createMood(name: "Sad", emoji: "😢", colorHex: 0x5A7EB5)
        state.updateMoodEmoji(mood, to: "😭")
        #expect(mood.emoji == "😭")
    }

    @Test @MainActor func deleteMoodRemovesFromStore() throws {
        let state = try makeTestState()
        let mood = state.createMood(name: "Tired", emoji: "😴", colorHex: 0x9B6B9E)
        #expect(state.allMoods.count == 1)
        state.deleteMood(mood)
        #expect(state.allMoods.count == 0)
    }

    @Test @MainActor func deleteMoodRemovesFromEntries() throws {
        let state = try makeTestState()
        let mood = state.createMood(name: "Excited", emoji: "🎉", colorHex: 0xB07A4F)
        let entry = JournalEntry(id: "dm-1", photoKey: .coffee,
                                 caption: "Test", date: Date(), place: "")
        entry.moods = [mood]
        state.modelContext?.insert(entry)
        try state.modelContext?.save()

        #expect(entry.moods.count == 1)
        state.deleteMood(mood)
        #expect(entry.moods.count == 0)
        #expect(state.allMoods.count == 0)
    }

    @Test @MainActor func deleteMoodLeavesOtherMoodsIntact() throws {
        let state = try makeTestState()
        let mood1 = state.createMood(name: "Happy", emoji: "😊", colorHex: 0xE08A6C)
        let mood2 = state.createMood(name: "Calm", emoji: "🧘", colorHex: 0x6B9B8A)
        let entry = JournalEntry(id: "dm-2", photoKey: .trail,
                                 caption: "Test", date: Date(), place: "")
        entry.moods = [mood1, mood2]
        state.modelContext?.insert(entry)
        try state.modelContext?.save()

        state.deleteMood(mood1)
        #expect(state.allMoods.count == 1)
        #expect(state.allMoods.first?.name == "Calm")
        #expect(entry.moods.count == 1)
        #expect(entry.moods.first?.name == "Calm")
    }
}

// MARK: - Caption Parsing Tests

@Suite("Caption Parsing Tests")
struct CaptionParsingTests {

    @Test("Empty string returns no blocks")
    func emptyStringReturnsNoBlocks() {
        let blocks = parseCaptionBlocks("")
        #expect(blocks.isEmpty)
    }

    @Test("Plain text returns single prose")
    func plainTextReturnsSingleProse() {
        let blocks = parseCaptionBlocks("Hello world")
        #expect(blocks.count == 1)
        if case .prose(let text) = blocks[0] {
            #expect(text == "Hello world")
        } else {
            Issue.record("Expected prose block")
        }
    }

    @Test("Multiline prose joined")
    func multilinePloseJoined() {
        let blocks = parseCaptionBlocks("Line one\nLine two\nLine three")
        #expect(blocks.count == 1)
        if case .prose(let text) = blocks[0] {
            #expect(text.contains("Line one"))
            #expect(text.contains("Line three"))
        } else {
            Issue.record("Expected prose block")
        }
    }

    @Test("Bullet lines")
    func bulletLines() {
        let text = "- First item\n- Second item\n- Third item"
        let blocks = parseCaptionBlocks(text)
        #expect(blocks.count == 3)

        for block in blocks {
            if case .bullet = block {
                // ok
            } else {
                Issue.record("Expected bullet block, got: \(block)")
            }
        }

        if case .bullet(let item) = blocks[0] {
            #expect(item == "First item")
        }
        if case .bullet(let item) = blocks[2] {
            #expect(item == "Third item")
        }
    }

    @Test("Numbered lines")
    func numberedLines() {
        let text = "1. Preheat oven\n2. Mix flour\n3. Bake"
        let blocks = parseCaptionBlocks(text)
        #expect(blocks.count == 3)

        if case .numbered(let n, let item) = blocks[0] {
            #expect(n == 1)
            #expect(item == "Preheat oven")
        } else {
            Issue.record("Expected numbered block")
        }

        if case .numbered(let n, let item) = blocks[2] {
            #expect(n == 3)
            #expect(item == "Bake")
        } else {
            Issue.record("Expected numbered block")
        }
    }

    @Test("Mixed content")
    func mixedContent() {
        let text = "My Recipe\n- flour\n- sugar\n1. Mix\n2. Bake\nEnjoy!"
        let blocks = parseCaptionBlocks(text)

        #expect(blocks.count == 6)

        if case .prose(let t) = blocks[0] { #expect(t == "My Recipe") }
        if case .bullet(let t) = blocks[1] { #expect(t == "flour") }
        if case .bullet(let t) = blocks[2] { #expect(t == "sugar") }
        if case .numbered(let n, _) = blocks[3] { #expect(n == 1) }
        if case .numbered(let n, _) = blocks[4] { #expect(n == 2) }
        if case .prose(let t) = blocks[5] { #expect(t == "Enjoy!") }
    }

    @Test("Bullet without space is not bullet")
    func bulletWithoutSpaceIsNotBullet() {
        let blocks = parseCaptionBlocks("-nospace")
        #expect(blocks.count == 1)
        if case .prose = blocks[0] {
            // correct
        } else {
            Issue.record("Expected prose for '-nospace'")
        }
    }

    @Test("Numbered without space is not numbered")
    func numberedWithoutSpaceIsNotNumbered() {
        let blocks = parseCaptionBlocks("1.nospace")
        #expect(blocks.count == 1)
        if case .prose = blocks[0] {
            // correct
        } else {
            Issue.record("Expected prose for '1.nospace'")
        }
    }

    @Test("High numbered items")
    func highNumberedItems() {
        let blocks = parseCaptionBlocks("42. Answer to everything")
        #expect(blocks.count == 1)
        if case .numbered(let n, let item) = blocks[0] {
            #expect(n == 42)
            #expect(item == "Answer to everything")
        }
    }

    @Test("Caption line spacing values")
    func captionLineSpacingValues() {
        #expect(captionLineSpacing(for: .hand) == 2)
        #expect(captionLineSpacing(for: .serif) == 6)
        #expect(captionLineSpacing(for: .sans) == 6)
    }

    @Test("Caption size hand gets boost")
    func captionSizeHandGetsBoost() {
        #expect(captionSize(for: .hand, base: 16) == 24)
        #expect(captionSize(for: .serif, base: 16) == 16)
        #expect(captionSize(for: .sans, base: 16) == 16)
    }
}

// MARK: - Photo Store Tests

@Suite("Photo Store Tests")
struct PhotoStoreTests {

    private func makeTestJPEG() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        let image = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
        return image.jpegData(compressionQuality: 0.5)!
    }

    @Test("Save returns filename")
    func saveReturnsFilename() throws {
        let data = makeTestJPEG()
        let filename = try PhotoStore.save(data)
        #expect(filename.hasPrefix("IMG_"))
        #expect(filename.hasSuffix(".jpg"))
        PhotoStore.delete(filename)
    }

    @Test("Save and load round trip")
    func saveAndLoadRoundTrip() throws {
        let data = makeTestJPEG()
        let filename = try PhotoStore.save(data)
        let loaded = PhotoStore.load(filename)
        #expect(loaded != nil)
        PhotoStore.delete(filename)
    }

    @Test("Load data returns bytes")
    func loadDataReturnsBytes() throws {
        let data = makeTestJPEG()
        let filename = try PhotoStore.save(data)
        let loadedData = PhotoStore.loadData(filename)
        #expect(loadedData != nil)
        #expect(!loadedData!.isEmpty)
        PhotoStore.delete(filename)
    }

    @Test("Delete removes file")
    func deleteRemovesFile() throws {
        let data = makeTestJPEG()
        let filename = try PhotoStore.save(data)
        PhotoStore.delete(filename)
        let loaded = PhotoStore.load(filename)
        #expect(loaded == nil)
    }

    @Test("Load nonexistent returns nil")
    func loadNonexistentReturnsNil() {
        let result = PhotoStore.load("nonexistent_file_12345.jpg")
        #expect(result == nil)
    }

    @Test("Load data nonexistent returns nil")
    func loadDataNonexistentReturnsNil() {
        let result = PhotoStore.loadData("nonexistent_file_12345.jpg")
        #expect(result == nil)
    }

    @Test("Saved filenames are unique")
    func savedFilenamesAreUnique() throws {
        let data = makeTestJPEG()
        let f1 = try PhotoStore.save(data)
        let f2 = try PhotoStore.save(data)
        #expect(f1 != f2)
        PhotoStore.delete(f1)
        PhotoStore.delete(f2)
    }

    @Test("Save generates thumbnail")
    func saveGeneratesThumbnail() throws {
        let data = makeTestJPEG()
        let filename = try PhotoStore.save(data)
        let thumb = PhotoStore.loadThumbnail(filename)
        #expect(thumb != nil)
        PhotoStore.delete(filename)
    }

    @Test("Load thumbnail falls back to full image")
    func loadThumbnailFallsBackToFullImage() throws {
        let data = makeTestJPEG()
        let filename = try PhotoStore.save(data)
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let thumbURL = docs.appendingPathComponent("Photos/THUMB_\(filename)")
        try? FileManager.default.removeItem(at: thumbURL)
        let result = PhotoStore.loadThumbnail(filename)
        #expect(result != nil)
        PhotoStore.delete(filename)
    }

    @Test("Delete removes thumbnail too")
    func deleteRemovesThumbnailToo() throws {
        let data = makeTestJPEG()
        let filename = try PhotoStore.save(data)
        PhotoStore.delete(filename)
        let result = PhotoStore.loadThumbnail(filename)
        #expect(result == nil)
    }

    @Test("Generate thumbnail for existing file")
    func generateThumbnailForExistingFile() throws {
        let data = makeTestJPEG()
        let filename = try PhotoStore.save(data)
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let thumbURL = docs.appendingPathComponent("Photos/THUMB_\(filename)")
        try? FileManager.default.removeItem(at: thumbURL)
        let success = PhotoStore.generateThumbnail(for: filename)
        #expect(success)
        let thumb = PhotoStore.loadThumbnail(filename)
        #expect(thumb != nil)
        PhotoStore.delete(filename)
    }
}
