import SwiftUI
import SwiftData

enum AppScreen: Equatable {
    case home
    case camera
    case review
    case browse
    case entry(String)
    case saved

    /// Depth in the navigation hierarchy — used to pick push vs pop transitions.
    var depth: Int {
        switch self {
        case .home, .saved: return 0
        case .camera, .browse: return 1
        case .review, .entry: return 2
        }
    }
}

/// Browse list filters. Lives in AppState so filters survive opening an entry
/// and navigating back (BrowseView is recreated on each visit).
struct BrowseFilters {
    var searchText = ""
    var tags: [Tag] = []
    var moods: [Mood] = []
    var date: Date?
    var voiceOnly = false
    var calendarOpen = false

    var isActive: Bool {
        !searchText.isEmpty || !tags.isEmpty || !moods.isEmpty || date != nil || voiceOnly
    }
}

enum NavDirection {
    case forward
    case backward
}

@MainActor @Observable
class AppState {
    // MARK: - Persisted Settings (UserDefaults)

    var isDark: Bool {
        didSet { UserDefaults.standard.set(isDark, forKey: "isDark") }
    }
    var useOLED: Bool {
        didSet { UserDefaults.standard.set(useOLED, forKey: "useOLED") }
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
    /// Entry temporarily pinned for quick access from Home (e.g. a recipe while cooking).
    /// Persisted so it survives the app being terminated in the background.
    var pinnedEntryId: String? {
        didSet { UserDefaults.standard.set(pinnedEntryId, forKey: "pinnedEntryId") }
    }

    // MARK: - Navigation

    var screen: AppScreen = .home {
        didSet {
            navDirection = screen.depth >= oldValue.depth ? .forward : .backward
        }
    }
    var navDirection: NavDirection = .forward
    var settingsOpen: Bool = false
    var cameraMode: String = "photo"

    /// Entry id to restore the Browse scroll position to after viewing an entry.
    var browseAnchorId: String?
    /// Ordered ids of Browse's filtered list when an entry was opened from it, so
    /// swiping in the entry view stays within the filter. nil pages through all entries.
    var browseEntryIds: [String]?
    var browseFilters = BrowseFilters()

    // MARK: - Capture Flow

    var pendingPhotos: [PendingPhoto] = []
    var pendingDate: Date?
    var pendingPlace: String = ""
    /// Temp URL of a voice note recorded during the capture flow (nil if none).
    var pendingAudioURL: URL?
    var pendingAudioDuration: Double = 0

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

    var theme: JournalTheme { JournalTheme(isDark: isDark, useOLED: useOLED) }
    var latest: JournalEntry? {
        _ = refreshTrigger
        guard let context = modelContext else { return nil }
        var descriptor = FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    var entryCount: Int {
        _ = refreshTrigger
        guard let context = modelContext else { return 0 }
        return (try? context.fetchCount(FetchDescriptor<JournalEntry>())) ?? 0
    }

    func entryById(_ id: String) -> JournalEntry? {
        guard let context = modelContext else { return nil }
        let entryId = id
        var descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.id == entryId }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    // MARK: - Pinning

    /// The pinned entry, or nil if nothing is pinned or the entry no longer exists.
    var pinnedEntry: JournalEntry? {
        _ = refreshTrigger
        guard let id = pinnedEntryId else { return nil }
        return entryById(id)
    }

    func isPinned(_ id: String) -> Bool { pinnedEntryId == id }

    /// Pins the entry (replacing any previous pin), or unpins it if already pinned.
    func togglePin(_ id: String) {
        pinnedEntryId = isPinned(id) ? nil : id
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func openPinned() {
        guard let entry = pinnedEntry else { return }
        browseEntryIds = nil
        screen = .entry(entry.id)
    }

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard
        self.isDark = defaults.bool(forKey: "isDark")
        self.useOLED = defaults.bool(forKey: "useOLED")
        self.captionFont = CaptionFont(rawValue: defaults.string(forKey: "captionFont") ?? "") ?? .serif
        self.layout = LayoutStyle(rawValue: defaults.string(forKey: "layout") ?? "") ?? .classic
        self.name = defaults.string(forKey: "name") ?? ""
        self.pinnedEntryId = defaults.string(forKey: "pinnedEntryId")
    }

    // MARK: - Actions

    func savePage(caption: String, tags: [Tag] = [], moods: [Mood] = []) {
        guard !pendingPhotos.isEmpty, let context = modelContext else { return }

        // Persist all pending photos; keep only the ones that saved successfully.
        let filenames = pendingPhotos.compactMap { try? PhotoStore.save($0.data) }
        guard !filenames.isEmpty else { return }

        // Set importedAt when the photo's date differs from now (gallery import of old photo)
        let photoDate = pendingDate ?? Date()
        let importedAt = pendingDate != nil ? Date() : nil

        let entry = JournalEntry(
            id: JournalEntry.generateId(),
            photoFileNames: filenames,
            caption: caption.isEmpty ? "\u{2014}" : caption,
            date: photoDate,
            place: pendingPlace,
            importedAt: importedAt
        )
        entry.tags = tags
        entry.moods = moods

        // Persist an optional voice note recorded during this capture.
        if let audioURL = pendingAudioURL, let audioName = try? AudioStore.save(from: audioURL) {
            entry.audioFileName = audioName
            entry.audioDuration = pendingAudioDuration
        }

        context.insert(entry)
        try? context.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        screen = .saved
        pendingPhotos = []
        pendingAudioURL = nil
        pendingAudioDuration = 0

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

    func renameTag(_ tag: Tag, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tag.name = trimmed
        try? modelContext?.save()
    }

    func deleteTag(_ tag: Tag) {
        guard let context = modelContext else { return }
        // Remove the tag from all entries that reference it
        for entry in tag.entries {
            entry.tags.removeAll { $0.id == tag.id }
        }
        // Don't hold a deleted model in the Browse filters
        browseFilters.tags.removeAll { $0.id == tag.id }
        context.delete(tag)
        try? context.save()
    }

    // MARK: - Moods

    var allMoods: [Mood] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<Mood>(sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func createMood(name: String, emoji: String, colorHex: UInt) -> Mood {
        let mood = Mood(name: name, emoji: emoji, colorHex: colorHex)
        modelContext?.insert(mood)
        try? modelContext?.save()
        return mood
    }

    func renameMood(_ mood: Mood, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        mood.name = trimmed
        try? modelContext?.save()
    }

    func updateMoodEmoji(_ mood: Mood, to newEmoji: String) {
        let trimmed = newEmoji.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        mood.emoji = trimmed
        try? modelContext?.save()
    }

    func deleteMood(_ mood: Mood) {
        guard let context = modelContext else { return }
        for entry in mood.entries {
            entry.moods.removeAll { $0.id == mood.id }
        }
        browseFilters.moods.removeAll { $0.id == mood.id }
        context.delete(mood)
        try? context.save()
    }

    func deleteAllEntries() {
        guard let context = modelContext else { return }
        let allEntries = entries
        for entry in allEntries {
            // Delete photo files for real captures
            for filename in entry.resolvedFileNames {
                PhotoStore.delete(filename)
            }
            if let audio = entry.audioFileName {
                AudioStore.delete(audio)
            }
            context.delete(entry)
        }
        try? context.save()
        pinnedEntryId = nil
        screen = .home
    }
}
