import Testing
import Foundation
@testable import SpotJournal

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
}
