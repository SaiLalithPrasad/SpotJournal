import SwiftUI
import SwiftData

enum AppScreen: Equatable {
    case home
    case camera
    case review
    case browse
    case entry(String)
    case saved
}

@Observable
class AppState {
    // MARK: - Persisted Settings (UserDefaults)

    var isDark: Bool {
        didSet { UserDefaults.standard.set(isDark, forKey: "isDark") }
    }
    var captionFont: CaptionFont {
        didSet { UserDefaults.standard.set(captionFont.rawValue, forKey: "captionFont") }
    }
    var layout: LayoutStyle {
        didSet { UserDefaults.standard.set(layout.rawValue, forKey: "layout") }
    }
    var name: String {
        didSet { UserDefaults.standard.set(name, forKey: "name") }
    }

    // MARK: - Navigation

    var screen: AppScreen = .home
    var settingsOpen: Bool = false
    var cameraMode: String = "photo"

    // MARK: - Capture Flow

    var pendingPhotoData: Data?
    var pendingDate: Date?
    var pendingPlace: String = ""

    // MARK: - SwiftData

    var modelContext: ModelContext?
    var refreshTrigger: Int = 0

    var entries: [JournalEntry] {
        _ = refreshTrigger  // Force @Observable to re-evaluate when trigger changes
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Computed

    var theme: JournalTheme { JournalTheme(isDark: isDark) }
    var latest: JournalEntry? { entries.first }

    func entryById(_ id: String) -> JournalEntry? {
        guard let context = modelContext else { return nil }
        let entryId = id
        var descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.id == entryId }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard
        self.isDark = defaults.bool(forKey: "isDark")
        self.captionFont = CaptionFont(rawValue: defaults.string(forKey: "captionFont") ?? "") ?? .serif
        self.layout = LayoutStyle(rawValue: defaults.string(forKey: "layout") ?? "") ?? .classic
        self.name = defaults.string(forKey: "name") ?? ""
    }

    // MARK: - Actions

    func savePage(caption: String, tags: [Tag] = []) {
        guard let photoData = pendingPhotoData, let context = modelContext else { return }

        guard let filename = try? PhotoStore.save(photoData) else { return }

        // Set importedAt when the photo's date differs from now (gallery import of old photo)
        let photoDate = pendingDate ?? Date()
        let importedAt = pendingDate != nil ? Date() : nil

        let entry = JournalEntry(
            id: JournalEntry.generateId(),
            photoFileName: filename,
            caption: caption.isEmpty ? "\u{2014}" : caption,
            date: photoDate,
            place: pendingPlace,
            importedAt: importedAt
        )
        entry.tags = tags
        context.insert(entry)
        try? context.save()

        screen = .saved
        pendingPhotoData = nil

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            if self.screen == .saved {
                self.screen = .home
            }
        }
    }

    // MARK: - Tags

    var allTags: [Tag] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func createTag(name: String, colorHex: UInt) -> Tag {
        let tag = Tag(name: name, colorHex: colorHex)
        modelContext?.insert(tag)
        try? modelContext?.save()
        return tag
    }

    func deleteTag(_ tag: Tag) {
        guard let context = modelContext else { return }
        // Remove the tag from all entries that reference it
        for entry in tag.entries {
            entry.tags.removeAll { $0.id == tag.id }
        }
        context.delete(tag)
        try? context.save()
    }

    func deleteAllEntries() {
        guard let context = modelContext else { return }
        let allEntries = entries
        for entry in allEntries {
            // Delete photo files for real captures
            if let filename = entry.photoFileName {
                PhotoStore.delete(filename)
            }
            context.delete(entry)
        }
        try? context.save()
        screen = .home
    }
}
