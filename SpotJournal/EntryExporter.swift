import Foundation
import SwiftData

// MARK: - Archive Types

struct JournalArchive: Codable {
    let version: Int
    let exportedAt: Date
    let entries: [ArchiveEntry]
}

struct ArchiveEntry: Codable {
    let caption: String
    let date: Date
    let place: String
    let importedAt: Date?
    let photoData: Data?
    let placeholderKey: String?
    let tags: [ArchiveTag]
}

struct ArchiveTag: Codable {
    let name: String
    let colorHex: UInt
}

// MARK: - Exporter

enum EntryExporter {

    /// Builds a binary plist archive containing all entries and their photos.
    static func exportAll(_ entries: [JournalEntry]) throws -> Data {
        let archiveEntries = entries.map { entry -> ArchiveEntry in
            var photoData: Data?
            if let filename = entry.photoFileName {
                photoData = PhotoStore.loadData(filename)
            }

            let tags = entry.tags.map { ArchiveTag(name: $0.name, colorHex: $0.colorHex) }

            return ArchiveEntry(
                caption: entry.caption,
                date: entry.date,
                place: entry.place,
                importedAt: entry.importedAt,
                photoData: photoData,
                placeholderKey: entry.photoKeyRaw,
                tags: tags
            )
        }

        let archive = JournalArchive(
            version: 1,
            exportedAt: Date(),
            entries: archiveEntries
        )

        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        return try encoder.encode(archive)
    }

    /// Writes the archive to a temp file and returns its URL.
    static func exportToFile(_ entries: [JournalEntry]) throws -> URL {
        let data = try exportAll(entries)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())
        let filename = "SpotJournal-\(dateStr).spotjournal"
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    /// Imports entries from an archive file into the given context.
    /// Returns the number of entries imported.
    static func importArchive(_ data: Data, into context: ModelContext) throws -> Int {
        let archive = try PropertyListDecoder().decode(JournalArchive.self, from: data)

        // Load existing entry dates for deduplication
        let existingEntries = (try? context.fetch(FetchDescriptor<JournalEntry>())) ?? []
        let existingDates = Set(existingEntries.map { $0.date.timeIntervalSince1970 })

        // Load existing tags for reuse
        let existingTags = (try? context.fetch(FetchDescriptor<Tag>())) ?? []

        var importedCount = 0

        for archiveEntry in archive.entries {
            // Skip duplicates (same timestamp)
            if existingDates.contains(archiveEntry.date.timeIntervalSince1970) {
                continue
            }

            let entry: JournalEntry

            if let photoData = archiveEntry.photoData {
                // Real photo entry
                guard let filename = try? PhotoStore.save(photoData) else { continue }
                entry = JournalEntry(
                    id: JournalEntry.generateId(),
                    photoFileName: filename,
                    caption: archiveEntry.caption,
                    date: archiveEntry.date,
                    place: archiveEntry.place,
                    importedAt: archiveEntry.importedAt
                )
            } else if let placeholderKey = archiveEntry.placeholderKey,
                      let key = PhotoKey(rawValue: placeholderKey) {
                // Placeholder entry
                entry = JournalEntry(
                    id: JournalEntry.generateId(),
                    photoKey: key,
                    caption: archiveEntry.caption,
                    date: archiveEntry.date,
                    place: archiveEntry.place
                )
                entry.importedAt = archiveEntry.importedAt
            } else {
                continue
            }

            // Resolve tags
            var entryTags: [Tag] = []
            for archiveTag in archiveEntry.tags {
                if let existing = existingTags.first(where: { $0.name == archiveTag.name }) {
                    entryTags.append(existing)
                } else {
                    let newTag = Tag(name: archiveTag.name, colorHex: archiveTag.colorHex)
                    context.insert(newTag)
                    entryTags.append(newTag)
                }
            }
            entry.tags = entryTags

            context.insert(entry)
            importedCount += 1
        }

        try context.save()
        return importedCount
    }
}
