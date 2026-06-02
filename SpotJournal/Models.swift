import Foundation
import SwiftUI
import SwiftData
import UIKit

// MARK: - Settings Enums

enum CaptionFont: String, CaseIterable {
    case serif, sans, hand

    var label: String {
        switch self {
        case .serif: return "Typeset"
        case .sans: return "Plain"
        case .hand: return "Written"
        }
    }

    var sample: String { "The morning was quiet." }
}

enum LayoutStyle: String, CaseIterable {
    case classic, offset, split

    var label: String {
        switch self {
        case .classic: return "Classic"
        case .offset: return "Offset"
        case .split: return "Split"
        }
    }

    var blurb: String {
        switch self {
        case .classic: return "Photo at the top, caption below, date at the foot."
        case .offset: return "Photo pushed to one side, caption wraps beside it."
        case .split: return "Photo fills the upper half, caption and date stack below a rule."
        }
    }
}

// MARK: - Photo Types

enum PhotoKey: String, CaseIterable {
    case window, coffee, trail, plate
}

enum PhotoSource {
    case placeholder(PhotoKey)
    case file(String)
    case data(Data)
}

// MARK: - Tag (SwiftData)

@Model
final class Tag {
    @Attribute(.unique) var id: String
    var name: String
    var colorHex: UInt

    @Relationship(inverse: \JournalEntry.tags)
    var entries: [JournalEntry] = []

    init(name: String, colorHex: UInt) {
        self.id = UUID().uuidString
        self.name = name
        self.colorHex = colorHex
    }

    var color: Color { Color(hex: colorHex) }

    static let defaultColors: [UInt] = [
        0xD97757, 0x5B8C5A, 0x5A7EB5, 0xC4A35A,
        0x9B6B9E, 0xE08A6C, 0x6B9B8A, 0xB07A4F
    ]
}

// MARK: - Mood (SwiftData)

@Model
final class Mood {
    @Attribute(.unique) var id: String
    var name: String
    var emoji: String
    var colorHex: UInt = 0xD97757

    @Relationship(inverse: \JournalEntry.moods)
    var entries: [JournalEntry] = []

    init(name: String, emoji: String, colorHex: UInt = 0xD97757) {
        self.id = UUID().uuidString
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
    }

    var color: Color { Color(hex: colorHex) }

    static let defaultEmojis: [String] = [
        "\u{1F60A}", "\u{1F622}", "\u{1F624}", "\u{1F4DA}",
        "\u{1F9D8}", "\u{1F389}", "\u{1F634}", "\u{1F64F}",
        "\u{1F60D}", "\u{1F914}", "\u{1F62E}", "\u{1F525}"
    ]

    static let defaultSeeds: [(name: String, emoji: String, colorHex: UInt)] = [
        ("Happy",            "\u{1F60A}", 0xE08A6C),
        ("Sad",              "\u{1F622}", 0x5A7EB5),
        ("Grumpy",           "\u{1F624}", 0xD97757),
        ("Lessons to Learn", "\u{1F4DA}", 0xC4A35A),
        ("Calm",             "\u{1F9D8}", 0x6B9B8A),
        ("Excited",          "\u{1F389}", 0xB07A4F),
        ("Tired",            "\u{1F634}", 0x9B6B9E),
        ("Grateful",         "\u{1F64F}", 0x5B8C5A)
    ]
}

// MARK: - Journal Entry (SwiftData)

@Model
final class JournalEntry {
    @Attribute(.unique) var id: String
    var photoKeyRaw: String?
    var photoFileName: String?
    var caption: String
    var date: Date
    var place: String
    var importedAt: Date?
    var tags: [Tag] = []
    var moods: [Mood] = []

    var photoKey: PhotoKey? {
        guard let raw = photoKeyRaw else { return nil }
        return PhotoKey(rawValue: raw)
    }

    var isPlaceholder: Bool { photoKeyRaw != nil }

    var photoSource: PhotoSource {
        if let key = photoKey { return .placeholder(key) }
        if let file = photoFileName { return .file(file) }
        return .placeholder(.window)
    }

    static func generateId() -> String {
        "e-\(Int(Date().timeIntervalSince1970))-\(Int.random(in: 1000...9999))"
    }

    /// Init for placeholder/seed entries
    init(id: String, photoKey: PhotoKey, caption: String, date: Date, place: String) {
        self.id = id
        self.photoKeyRaw = photoKey.rawValue
        self.photoFileName = nil
        self.caption = caption
        self.date = date
        self.place = place
        self.importedAt = nil
    }

    /// Init for real camera entries
    init(id: String, photoFileName: String, caption: String, date: Date, place: String, importedAt: Date? = nil) {
        self.id = id
        self.photoKeyRaw = nil
        self.photoFileName = photoFileName
        self.caption = caption
        self.date = date
        self.place = place
        self.importedAt = importedAt
    }
}

// MARK: - Sample Data

func makeSampleEntries() -> [JournalEntry] {
    [
        JournalEntry(id: "e-1", photoKey: .window,
            caption: "Light through the kitchen window again. There is a particular slant it takes in April that I have been trying to name for weeks.",
            date: makeDate(2026, 4, 17, 18, 42), place: "Cobble Hill, Brooklyn"),
        JournalEntry(id: "e-2", photoKey: .coffee,
            caption: "First cup from the new beans. Nutty, a little chocolate, not as bright as I was hoping. Trying a coarser grind tomorrow.",
            date: makeDate(2026, 4, 18, 7, 14), place: "Home"),
        JournalEntry(id: "e-3", photoKey: .trail,
            caption: "Walked the long way and the trail was empty. A good silence.",
            date: makeDate(2026, 4, 15, 8, 3), place: "Prospect Park"),
        JournalEntry(id: "e-4", photoKey: .plate,
            caption: "Made the pasta again. Still not right, but closer. The sauce wants more time.",
            date: makeDate(2026, 4, 12, 20, 17), place: "Home"),
        JournalEntry(id: "e-5", photoKey: .window,
            caption: "Rain all day. Read two chapters and slept an hour in the middle.",
            date: makeDate(2026, 4, 9, 15, 22), place: "Home"),
        JournalEntry(id: "e-6", photoKey: .coffee,
            caption: "Early meeting, early cup. I keep forgetting how much I like mornings.",
            date: makeDate(2026, 4, 3, 6, 48), place: "Home"),
        JournalEntry(id: "e-7", photoKey: .trail,
            caption: "First warm day. Everyone is out. A kid was naming every tree.",
            date: makeDate(2026, 3, 28, 11, 30), place: "Prospect Park"),
    ]
}

private func makeDate(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
    var c = DateComponents()
    c.year = y; c.month = m; c.day = d; c.hour = h; c.minute = min
    return Calendar.current.date(from: c) ?? Date()
}
