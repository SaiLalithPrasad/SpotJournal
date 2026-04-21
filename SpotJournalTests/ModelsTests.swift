import Testing
import Foundation
@testable import SpotJournal

struct ModelsTests {

    // MARK: - JournalEntry.generateId

    @Test func generateIdHasCorrectPrefix() {
        let id = JournalEntry.generateId()
        #expect(id.hasPrefix("e-"))
    }

    @Test func generateIdContainsTimestamp() {
        let before = Int(Date().timeIntervalSince1970)
        let id = JournalEntry.generateId()
        let after = Int(Date().timeIntervalSince1970)

        let parts = id.split(separator: "-")
        #expect(parts.count == 3)
        let timestamp = Int(parts[1])!
        #expect(timestamp >= before && timestamp <= after)
    }

    @Test func generateIdHasRandomSuffix() {
        let id = JournalEntry.generateId()
        let parts = id.split(separator: "-")
        let suffix = Int(parts[2])!
        #expect(suffix >= 1000 && suffix <= 9999)
    }

    @Test func generateIdProducesUniqueValues() {
        let ids = (0..<20).map { _ in JournalEntry.generateId() }
        let unique = Set(ids)
        #expect(unique.count == ids.count)
    }

    // MARK: - CaptionFont

    @Test func captionFontRawValues() {
        #expect(CaptionFont.serif.rawValue == "serif")
        #expect(CaptionFont.sans.rawValue == "sans")
        #expect(CaptionFont.hand.rawValue == "hand")
    }

    @Test func captionFontLabels() {
        #expect(CaptionFont.serif.label == "Typeset")
        #expect(CaptionFont.sans.label == "Plain")
        #expect(CaptionFont.hand.label == "Written")
    }

    @Test func captionFontSampleIsShared() {
        for font in CaptionFont.allCases {
            #expect(font.sample == "The morning was quiet.")
        }
    }

    @Test func captionFontCaseIterableCount() {
        #expect(CaptionFont.allCases.count == 3)
    }

    // MARK: - LayoutStyle

    @Test func layoutStyleRawValues() {
        #expect(LayoutStyle.classic.rawValue == "classic")
        #expect(LayoutStyle.offset.rawValue == "offset")
        #expect(LayoutStyle.split.rawValue == "split")
    }

    @Test func layoutStyleLabels() {
        #expect(LayoutStyle.classic.label == "Classic")
        #expect(LayoutStyle.offset.label == "Offset")
        #expect(LayoutStyle.split.label == "Split")
    }

    @Test func layoutStyleBlurbsAreNonEmpty() {
        for style in LayoutStyle.allCases {
            #expect(!style.blurb.isEmpty)
        }
    }

    // MARK: - PhotoKey

    @Test func photoKeyCases() {
        #expect(PhotoKey.allCases.count == 4)
        #expect(PhotoKey(rawValue: "window") == .window)
        #expect(PhotoKey(rawValue: "coffee") == .coffee)
        #expect(PhotoKey(rawValue: "trail") == .trail)
        #expect(PhotoKey(rawValue: "plate") == .plate)
        #expect(PhotoKey(rawValue: "invalid") == nil)
    }

    // MARK: - JournalEntry (placeholder init)

    @Test func placeholderEntryProperties() {
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

    // MARK: - JournalEntry (file init)

    @Test func fileEntryProperties() {
        let now = Date()
        let entry = JournalEntry(id: "test-2", photoFileName: "IMG_001.jpg",
                                 caption: "Test", date: now, place: "LA", importedAt: now)
        #expect(entry.isPlaceholder == false)
        #expect(entry.photoKey == nil)
        #expect(entry.photoFileName == "IMG_001.jpg")
        #expect(entry.importedAt != nil)
    }

    // MARK: - PhotoSource

    @Test func photoSourcePlaceholder() {
        let entry = JournalEntry(id: "ps-1", photoKey: .trail,
                                 caption: "", date: Date(), place: "")
        if case .placeholder(let key) = entry.photoSource {
            #expect(key == .trail)
        } else {
            Issue.record("Expected placeholder source")
        }
    }

    @Test func photoSourceFile() {
        let entry = JournalEntry(id: "ps-2", photoFileName: "test.jpg",
                                 caption: "", date: Date(), place: "")
        if case .file(let name) = entry.photoSource {
            #expect(name == "test.jpg")
        } else {
            Issue.record("Expected file source")
        }
    }

    // MARK: - Tag

    @Test func tagDefaultColors() {
        #expect(Tag.defaultColors.count == 8)
        #expect(Tag.defaultColors[0] == 0xD97757)
    }

    @Test func tagInit() {
        let tag = Tag(name: "Recipe", colorHex: 0xFF0000)
        #expect(tag.name == "Recipe")
        #expect(tag.colorHex == 0xFF0000)
        #expect(!tag.id.isEmpty)
    }

    // MARK: - Sample Data

    @Test func makeSampleEntriesCount() {
        let entries = makeSampleEntries()
        #expect(entries.count == 7)
    }

    @Test func sampleEntriesHaveUniqueIds() {
        let entries = makeSampleEntries()
        let ids = Set(entries.map(\.id))
        #expect(ids.count == entries.count)
    }
}
