import Testing
import Foundation
import SwiftData
@testable import SpotJournal

@Suite(.serialized)
struct EntryExporterTests {

    // MARK: - Archive Round-Trip

    @Test func archiveEncodesAndDecodes() throws {
        let entries = makeSampleEntries()
        let data = try EntryExporter.exportAll(entries)
        #expect(!data.isEmpty)

        let archive = try PropertyListDecoder().decode(JournalArchive.self, from: data)
        #expect(archive.version == 1)
        #expect(archive.entries.count == entries.count)
    }

    @Test func archivePreservesEntryFields() throws {
        let entry = JournalEntry(id: "rt-1", photoKey: .coffee,
                                 caption: "Test caption", date: Date(), place: "Brooklyn")
        let data = try EntryExporter.exportAll([entry])
        let archive = try PropertyListDecoder().decode(JournalArchive.self, from: data)
        let archived = archive.entries[0]

        #expect(archived.caption == "Test caption")
        #expect(archived.place == "Brooklyn")
        #expect(archived.placeholderKey == "coffee")
        #expect(archived.photoData == nil)
    }

    @Test func archivePreservesTags() throws {
        let entry = JournalEntry(id: "rt-2", photoKey: .trail,
                                 caption: "Tagged", date: Date(), place: "")
        let tag = Tag(name: "Recipe", colorHex: 0xFF0000)
        entry.tags = [tag]

        let data = try EntryExporter.exportAll([entry])
        let archive = try PropertyListDecoder().decode(JournalArchive.self, from: data)

        #expect(archive.entries[0].tags.count == 1)
        #expect(archive.entries[0].tags[0].name == "Recipe")
        #expect(archive.entries[0].tags[0].colorHex == 0xFF0000)
    }

    @Test func archiveExportDate() throws {
        let before = Date()
        let data = try EntryExporter.exportAll(makeSampleEntries())
        let after = Date()
        let archive = try PropertyListDecoder().decode(JournalArchive.self, from: data)

        #expect(archive.exportedAt >= before)
        #expect(archive.exportedAt <= after)
    }

    @Test func emptyEntriesExportSucceeds() throws {
        let data = try EntryExporter.exportAll([])
        let archive = try PropertyListDecoder().decode(JournalArchive.self, from: data)
        #expect(archive.entries.isEmpty)
    }

    // MARK: - Export to File

    @Test func exportToFileCreatesFile() throws {
        let entries = makeSampleEntries()
        let url = try EntryExporter.exportToFile(entries)
        #expect(url.pathExtension == "spotjournal")
        #expect(FileManager.default.fileExists(atPath: url.path))

        // Cleanup
        try? FileManager.default.removeItem(at: url)
    }

    @Test func exportToFileNameContainsDate() throws {
        let url = try EntryExporter.exportToFile([])
        let filename = url.lastPathComponent
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())
        #expect(filename.contains(dateStr))

        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Progress Callback

    @Test func exportAllReportsProgress() throws {
        let entries = makeSampleEntries()
        var progressValues: [Double] = []
        _ = try EntryExporter.exportAll(entries) { p in
            progressValues.append(p)
        }
        #expect(progressValues.count == entries.count)
        #expect(progressValues.last == 1.0)

        // Progress should be monotonically increasing
        for i in 1..<progressValues.count {
            #expect(progressValues[i] > progressValues[i - 1])
        }
    }

    // MARK: - PDF Export

    @Test func pdfExportProducesData() {
        let entries = makeSampleEntries()
        let data = PDFExporter.exportPDF(entries: entries, journalName: "Test", captionFont: .serif)
        #expect(!data.isEmpty)
        // PDF files start with %PDF
        let header = String(data: data.prefix(4), encoding: .ascii)
        #expect(header == "%PDF")
    }

    @Test func pdfExportEmptyEntries() {
        let data = PDFExporter.exportPDF(entries: [], journalName: "Empty", captionFont: .sans)
        #expect(!data.isEmpty)
        // Should still have a cover page
        let header = String(data: data.prefix(4), encoding: .ascii)
        #expect(header == "%PDF")
    }

    @Test func pdfExportToFileCreatesFile() {
        let url = PDFExporter.exportPDFToFile(entries: makeSampleEntries(),
                                               journalName: "Test Journal",
                                               captionFont: .serif)
        #expect(url.pathExtension == "pdf")
        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(url.lastPathComponent.contains("Test-Journal"))

        try? FileManager.default.removeItem(at: url)
    }

    @Test func pdfExportReportsProgress() {
        let entries = makeSampleEntries()
        var progressValues: [Double] = []
        _ = PDFExporter.exportPDF(entries: entries, journalName: "Test",
                                  captionFont: .serif) { p in
            progressValues.append(p)
        }
        #expect(progressValues.count == entries.count)
        #expect(progressValues.last == 1.0)
    }

    @Test func pdfExportWithBulletCaption() {
        let entry = JournalEntry(id: "pdf-1", photoKey: .plate,
                                 caption: "Ingredients:\n- flour\n- sugar\n- butter\n1. Mix\n2. Bake",
                                 date: Date(), place: "Kitchen")
        let data = PDFExporter.exportPDF(entries: [entry], journalName: "Recipes", captionFont: .hand)
        #expect(!data.isEmpty)
    }

    @Test func pdfExportFallbackJournalName() {
        let url = PDFExporter.exportPDFToFile(entries: [], journalName: "", captionFont: .sans)
        #expect(url.lastPathComponent.contains("SpotJournal"))
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Streaming Archive (v2)

    @Test func exportToFileCreatesV2Format() throws {
        let entries = makeSampleEntries()
        let url = try EntryExporter.exportToFile(entries)
        let data = try Data(contentsOf: url, options: .mappedIfSafe)

        // Should start with "SPOTJNL2" magic bytes
        let magic = String(data: data.prefix(8), encoding: .utf8)
        #expect(magic == "SPOTJNL2")

        try? FileManager.default.removeItem(at: url)
    }

    @Test func exportToFileReportsProgress() throws {
        let entries = makeSampleEntries()
        var progressValues: [Double] = []
        let url = try EntryExporter.exportToFile(entries) { p in
            progressValues.append(p)
        }
        #expect(progressValues.count == entries.count)
        #expect(progressValues.last == 1.0)

        for i in 1..<progressValues.count {
            #expect(progressValues[i] > progressValues[i - 1])
        }

        try? FileManager.default.removeItem(at: url)
    }

    /// Copy exported file to a unique path to avoid race conditions with parallel tests.
    private func uniqueCopy(of url: URL) throws -> URL {
        let unique = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("\(UUID().uuidString).spotjournal")
        try FileManager.default.copyItem(at: url, to: unique)
        return unique
    }

    @Test @MainActor func v2ExportImportRoundTrip() throws {
        // Export some entries
        let original = makeSampleEntries()
        let exportedURL = try EntryExporter.exportToFile(original)
        let url = try uniqueCopy(of: exportedURL)
        try? FileManager.default.removeItem(at: exportedURL)

        // Create in-memory SwiftData context for import
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: JournalEntry.self, Tag.self, Mood.self, configurations: config)
        let context = container.mainContext

        // Import from the v2 file
        let count = try EntryExporter.importFromFile(url, into: context)
        #expect(count == original.count)

        // Verify entries were imported
        let imported = try context.fetch(FetchDescriptor<JournalEntry>())
        #expect(imported.count == original.count)

        // Verify fields preserved
        let sortedOriginal = original.sorted { $0.caption < $1.caption }
        let sortedImported = imported.sorted { $0.caption < $1.caption }
        for (orig, imp) in zip(sortedOriginal, sortedImported) {
            #expect(imp.caption == orig.caption)
            #expect(imp.place == orig.place)
        }

        try? FileManager.default.removeItem(at: url)
    }

    @Test @MainActor func v2ImportDeduplicatesByDate() throws {
        let entries = [JournalEntry(id: "dup-1", photoKey: .coffee,
                                     caption: "Test", date: Date(), place: "NYC")]
        let exportedURL = try EntryExporter.exportToFile(entries)
        let url = try uniqueCopy(of: exportedURL)
        try? FileManager.default.removeItem(at: exportedURL)

        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: JournalEntry.self, Tag.self, Mood.self, configurations: config)
        let context = container.mainContext

        // Import twice
        let first = try EntryExporter.importFromFile(url, into: context)
        #expect(first == 1)
        let second = try EntryExporter.importFromFile(url, into: context)
        #expect(second == 0)  // Deduplicated

        let all = try context.fetch(FetchDescriptor<JournalEntry>())
        #expect(all.count == 1)

        try? FileManager.default.removeItem(at: url)
    }

    @Test @MainActor func v2ImportPreservesTags() throws {
        let entry = JournalEntry(id: "tag-rt", photoKey: .trail,
                                  caption: "Tagged entry", date: Date(), place: "")
        let tag = Tag(name: "Travel", colorHex: 0x2E86AB)
        entry.tags = [tag]

        let exportedURL = try EntryExporter.exportToFile([entry])
        let url = try uniqueCopy(of: exportedURL)
        try? FileManager.default.removeItem(at: exportedURL)

        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: JournalEntry.self, Tag.self, Mood.self, configurations: config)
        let context = container.mainContext

        let count = try EntryExporter.importFromFile(url, into: context)
        #expect(count == 1)

        let imported = try context.fetch(FetchDescriptor<JournalEntry>())
        #expect(imported[0].tags.count == 1)
        #expect(imported[0].tags[0].name == "Travel")
        #expect(imported[0].tags[0].colorHex == 0x2E86AB)

        try? FileManager.default.removeItem(at: url)
    }

    @Test func archivePreservesMoods() throws {
        let entry = JournalEntry(id: "rt-m", photoKey: .trail,
                                 caption: "Moody", date: Date(), place: "")
        let mood = Mood(name: "Happy", emoji: "\u{1F60A}")
        entry.moods = [mood]

        let data = try EntryExporter.exportAll([entry])
        let archive = try PropertyListDecoder().decode(JournalArchive.self, from: data)

        #expect(archive.entries[0].moods?.count == 1)
        #expect(archive.entries[0].moods?[0].name == "Happy")
        #expect(archive.entries[0].moods?[0].emoji == "\u{1F60A}")
    }

    @Test @MainActor func v2ImportPreservesMoods() throws {
        let entry = JournalEntry(id: "mood-rt", photoKey: .trail,
                                  caption: "Moody entry", date: Date(), place: "")
        let mood = Mood(name: "Calm", emoji: "\u{1F9D8}")
        entry.moods = [mood]

        let exportedURL = try EntryExporter.exportToFile([entry])
        let url = try uniqueCopy(of: exportedURL)
        try? FileManager.default.removeItem(at: exportedURL)

        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: JournalEntry.self, Tag.self, Mood.self, configurations: config)
        let context = container.mainContext

        let count = try EntryExporter.importFromFile(url, into: context)
        #expect(count == 1)

        let imported = try context.fetch(FetchDescriptor<JournalEntry>())
        #expect(imported[0].moods.count == 1)
        #expect(imported[0].moods[0].name == "Calm")
        #expect(imported[0].moods[0].emoji == "\u{1F9D8}")

        try? FileManager.default.removeItem(at: url)
    }
}
