import Foundation
import SwiftData
import UIKit
import CoreText
import SwiftUI

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
    let moods: [ArchiveMood]?
}

struct ArchiveTag: Codable {
    let name: String
    let colorHex: UInt
}

struct ArchiveMood: Codable {
    let name: String
    let emoji: String
    let colorHex: UInt?
}

// MARK: - Streaming Archive (v2)

private let archiveMagic = Data("SPOTJNL2".utf8)

struct ArchiveManifest: Codable {
    let version: Int
    let exportedAt: Date
    let entries: [ManifestEntry]
}

struct ManifestEntry: Codable {
    let caption: String
    let date: Date
    let place: String
    let importedAt: Date?
    let photoFilename: String?
    let placeholderKey: String?
    let tags: [ArchiveTag]
    let moods: [ArchiveMood]?
}

// MARK: - Exporter

enum EntryExporter {

    /// Builds a binary plist archive containing all entries and their photos.
    static func exportAll(_ entries: [JournalEntry], progress: ((Double) -> Void)? = nil) throws -> Data {
        let total = Double(entries.count)
        let archiveEntries = entries.enumerated().map { index, entry -> ArchiveEntry in
            var photoData: Data?
            if let filename = entry.photoFileName {
                photoData = PhotoStore.loadData(filename)
            }

            let tags = entry.tags.map { ArchiveTag(name: $0.name, colorHex: $0.colorHex) }
            let moods = entry.moods.map { ArchiveMood(name: $0.name, emoji: $0.emoji, colorHex: $0.colorHex) }

            progress?(Double(index + 1) / max(total, 1))

            return ArchiveEntry(
                caption: entry.caption,
                date: entry.date,
                place: entry.place,
                importedAt: entry.importedAt,
                photoData: photoData,
                placeholderKey: entry.photoKeyRaw,
                tags: tags,
                moods: moods
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

    /// Writes the archive to a temp file using streaming I/O.
    /// Only one photo is in memory at a time, preventing OOM on large journals.
    static func exportToFile(_ entries: [JournalEntry], progress: ((Double) -> Void)? = nil) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())
        let filename = "SpotJournal-\(dateStr).spotjournal"
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)

        try? FileManager.default.removeItem(at: url)
        FileManager.default.createFile(atPath: url.path, contents: nil)
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }

        let total = Double(entries.count)

        // Magic bytes
        try handle.write(contentsOf: archiveMagic)

        // Build manifest (lightweight — no photo data)
        let manifestEntries = entries.map { entry in
            ManifestEntry(
                caption: entry.caption,
                date: entry.date,
                place: entry.place,
                importedAt: entry.importedAt,
                photoFilename: entry.photoFileName,
                placeholderKey: entry.photoKeyRaw,
                tags: entry.tags.map { ArchiveTag(name: $0.name, colorHex: $0.colorHex) },
                moods: entry.moods.map { ArchiveMood(name: $0.name, emoji: $0.emoji, colorHex: $0.colorHex) }
            )
        }
        let manifest = ArchiveManifest(version: 2, exportedAt: Date(), entries: manifestEntries)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let manifestData = try encoder.encode(manifest)

        try writeUInt32(UInt32(manifestData.count), to: handle)
        try handle.write(contentsOf: manifestData)

        // Stream photos one at a time
        for (index, entry) in entries.enumerated() {
            try autoreleasepool {
                if let filename = entry.photoFileName, let photoData = PhotoStore.loadData(filename) {
                    try writeUInt32(UInt32(photoData.count), to: handle)
                    try handle.write(contentsOf: photoData)
                } else {
                    try writeUInt32(0, to: handle)
                }
            }
            progress?(Double(index + 1) / max(total, 1))
        }

        return url
    }

    private static func writeUInt32(_ value: UInt32, to handle: FileHandle) throws {
        var le = value.littleEndian
        try handle.write(contentsOf: Data(bytes: &le, count: 4))
    }

    private static func readUInt32(from handle: FileHandle) throws -> UInt32 {
        guard let data = try handle.read(upToCount: 4), data.count == 4 else {
            throw NSError(domain: "SpotJournal", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unexpected end of archive"])
        }
        return data.withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
    }

    /// Imports entries from an archive file URL using streaming I/O.
    /// Detects v2 (streaming) vs v1 (binary plist) format automatically.
    static func importFromFile(_ url: URL, into context: ModelContext) throws -> Int {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        // Read first 8 bytes to detect format
        let header = try handle.read(upToCount: 8)
        try handle.seek(toOffset: 0)

        if header == archiveMagic {
            return try importV2(handle: handle, into: context)
        }

        // Legacy v1: load as Data (memory-mapped for efficiency)
        try handle.close()
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        return try importArchive(data, into: context)
    }

    /// Streaming import for v2 archives. Only one photo in memory at a time.
    private static func importV2(handle: FileHandle, into context: ModelContext) throws -> Int {
        // Skip magic
        try handle.seek(toOffset: 8)

        // Read manifest
        let manifestLength = try readUInt32(from: handle)
        guard let manifestData = try handle.read(upToCount: Int(manifestLength)),
              manifestData.count == Int(manifestLength) else {
            throw NSError(domain: "SpotJournal", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid archive manifest"])
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let manifest = try decoder.decode(ArchiveManifest.self, from: manifestData)

        // Load existing dates for deduplication
        let existingEntries = (try? context.fetch(FetchDescriptor<JournalEntry>())) ?? []
        let existingDates = Set(existingEntries.map { $0.date.timeIntervalSince1970 })
        let existingTags = (try? context.fetch(FetchDescriptor<Tag>())) ?? []
        var existingMoods = (try? context.fetch(FetchDescriptor<Mood>())) ?? []

        var importedCount = 0

        for manifestEntry in manifest.entries {
            // Read photo data for this entry (even if skipping, to advance file position)
            let photoLength = try readUInt32(from: handle)
            let photoData: Data? = photoLength > 0
                ? try handle.read(upToCount: Int(photoLength))
                : nil

            // Skip duplicates
            if existingDates.contains(manifestEntry.date.timeIntervalSince1970) {
                continue
            }

            let entry: JournalEntry

            if let photoData {
                guard let filename = try? PhotoStore.save(photoData) else { continue }
                entry = JournalEntry(
                    id: JournalEntry.generateId(),
                    photoFileName: filename,
                    caption: manifestEntry.caption,
                    date: manifestEntry.date,
                    place: manifestEntry.place,
                    importedAt: manifestEntry.importedAt
                )
            } else if let placeholderKey = manifestEntry.placeholderKey,
                      let key = PhotoKey(rawValue: placeholderKey) {
                entry = JournalEntry(
                    id: JournalEntry.generateId(),
                    photoKey: key,
                    caption: manifestEntry.caption,
                    date: manifestEntry.date,
                    place: manifestEntry.place
                )
                entry.importedAt = manifestEntry.importedAt
            } else {
                continue
            }

            // Resolve tags
            var entryTags: [Tag] = []
            for archiveTag in manifestEntry.tags {
                if let existing = existingTags.first(where: { $0.name == archiveTag.name }) {
                    entryTags.append(existing)
                } else {
                    let newTag = Tag(name: archiveTag.name, colorHex: archiveTag.colorHex)
                    context.insert(newTag)
                    entryTags.append(newTag)
                }
            }
            entry.tags = entryTags

            // Resolve moods
            var entryMoods: [Mood] = []
            for archiveMood in manifestEntry.moods ?? [] {
                if let existing = existingMoods.first(where: { $0.name == archiveMood.name }) {
                    entryMoods.append(existing)
                } else {
                    let newMood = Mood(
                        name: archiveMood.name,
                        emoji: archiveMood.emoji,
                        colorHex: archiveMood.colorHex ?? Tag.defaultColors[0]
                    )
                    context.insert(newMood)
                    existingMoods.append(newMood)
                    entryMoods.append(newMood)
                }
            }
            entry.moods = entryMoods

            context.insert(entry)
            importedCount += 1
        }

        try context.save()
        return importedCount
    }

    /// Imports entries from legacy v1 binary plist data.
    /// Returns the number of entries imported.
    static func importArchive(_ data: Data, into context: ModelContext) throws -> Int {
        let archive = try PropertyListDecoder().decode(JournalArchive.self, from: data)

        // Load existing entry dates for deduplication
        let existingEntries = (try? context.fetch(FetchDescriptor<JournalEntry>())) ?? []
        let existingDates = Set(existingEntries.map { $0.date.timeIntervalSince1970 })

        // Load existing tags for reuse
        let existingTags = (try? context.fetch(FetchDescriptor<Tag>())) ?? []
        var existingMoods = (try? context.fetch(FetchDescriptor<Mood>())) ?? []

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

            // Resolve moods
            var entryMoods: [Mood] = []
            for archiveMood in archiveEntry.moods ?? [] {
                if let existing = existingMoods.first(where: { $0.name == archiveMood.name }) {
                    entryMoods.append(existing)
                } else {
                    let newMood = Mood(
                        name: archiveMood.name,
                        emoji: archiveMood.emoji,
                        colorHex: archiveMood.colorHex ?? Tag.defaultColors[0]
                    )
                    context.insert(newMood)
                    existingMoods.append(newMood)
                    entryMoods.append(newMood)
                }
            }
            entry.moods = entryMoods

            context.insert(entry)
            importedCount += 1
        }

        try context.save()
        return importedCount
    }
}

// MARK: - PDF Exporter

enum PDFExporter {

    // MARK: Layout Constants

    private struct Layout {
        static let pageWidth: CGFloat = 612
        static let pageHeight: CGFloat = 792
        static let marginH: CGFloat = 48
        static let marginTop: CGFloat = 48
        static let marginBottom: CGFloat = 48
        static let contentWidth: CGFloat = pageWidth - (marginH * 2)
        static let contentHeight: CGFloat = pageHeight - marginTop - marginBottom
        static let maxPhotoHeight: CGFloat = pageHeight * 0.40
        static let photoCaptionGap: CGFloat = 20
        static let captionFontSize: CGFloat = 13
        static let captionLineSpacing: CGFloat = 5
        static let bulletIndent: CGFloat = 16
        static let numberedLabelWidth: CGFloat = 24
        static let metaFontSize: CGFloat = 9
        static let metaTopPadding: CGFloat = 16
        static let tagFontSize: CGFloat = 8.5
        static let tagChipPaddingH: CGFloat = 6
        static let tagChipPaddingV: CGFloat = 3
        static let tagChipCorner: CGFloat = 4
        static let tagSpacing: CGFloat = 6
        static let coverTitleSize: CGFloat = 28
        static let coverMetaSize: CGFloat = 11
        static let pageNumberSize: CGFloat = 8
        static let pageNumberBottom: CGFloat = 28
    }

    private static let inkDark = UIColor(red: 0.16, green: 0.14, blue: 0.11, alpha: 1)
    private static let inkMedium = UIColor(red: 0.35, green: 0.31, blue: 0.24, alpha: 1)
    private static let inkLight = UIColor(red: 0.54, green: 0.50, blue: 0.42, alpha: 1)

    // MARK: Public API

    static func exportPDFToFile(
        entries: [JournalEntry],
        journalName: String,
        captionFont: CaptionFont,
        progress: ((Double) -> Void)? = nil
    ) -> URL {
        let data = exportPDF(entries: entries, journalName: journalName,
                             captionFont: captionFont, progress: progress)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())
        let safeName = journalName.isEmpty ? "SpotJournal"
            : journalName.replacingOccurrences(of: " ", with: "-")
        let filename = "\(safeName)-\(dateStr).pdf"
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
        try? data.write(to: url, options: .atomic)
        return url
    }

    static func exportPDF(
        entries: [JournalEntry],
        journalName: String,
        captionFont: CaptionFont,
        progress: ((Double) -> Void)? = nil
    ) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: Layout.pageWidth, height: Layout.pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let sorted = entries.sorted { $0.date < $1.date }
        let total = Double(sorted.count)

        let data = renderer.pdfData { context in
            drawCoverPage(context: context, pageRect: pageRect,
                          journalName: journalName, entries: sorted)
            var pageNumber = 2
            for (index, entry) in sorted.enumerated() {
                drawEntryPages(entry: entry, context: context, pageRect: pageRect,
                               captionFont: captionFont, pageNumber: &pageNumber)
                progress?(Double(index + 1) / max(total, 1))
            }
        }
        return data
    }

    // MARK: - Cover Page

    private static func drawCoverPage(
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        journalName: String,
        entries: [JournalEntry]
    ) {
        context.beginPage()
        let centerX = pageRect.midX
        var y: CGFloat = pageRect.height * 0.35

        // Title
        let title = journalName.isEmpty ? "My Journal" : journalName
        let titleFont = UIFont(name: "Georgia-Bold", size: Layout.coverTitleSize)
            ?? UIFont.systemFont(ofSize: Layout.coverTitleSize, weight: .bold)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: inkDark
        ]
        let titleSize = (title as NSString).size(withAttributes: titleAttrs)
        (title as NSString).draw(
            at: CGPoint(x: centerX - titleSize.width / 2, y: y),
            withAttributes: titleAttrs
        )
        y += titleSize.height + 12

        // Hairline rule
        let rulePath = UIBezierPath()
        rulePath.move(to: CGPoint(x: centerX - 40, y: y))
        rulePath.addLine(to: CGPoint(x: centerX + 40, y: y))
        inkLight.withAlphaComponent(0.4).setStroke()
        rulePath.lineWidth = 0.5
        rulePath.stroke()
        y += 16

        // Date range
        if let first = entries.first, let last = entries.last {
            let df = DateFormatter()
            df.dateFormat = "MMMM d, yyyy"
            let rangeStr = "\(df.string(from: first.date)) \u{2013} \(df.string(from: last.date))"
            let rangeFont = UIFont(name: "Georgia", size: Layout.coverMetaSize)
                ?? UIFont.systemFont(ofSize: Layout.coverMetaSize)
            let rangeAttrs: [NSAttributedString.Key: Any] = [
                .font: rangeFont,
                .foregroundColor: inkMedium
            ]
            let rangeSize = (rangeStr as NSString).size(withAttributes: rangeAttrs)
            (rangeStr as NSString).draw(
                at: CGPoint(x: centerX - rangeSize.width / 2, y: y),
                withAttributes: rangeAttrs
            )
            y += rangeSize.height + 8
        }

        // Entry count
        let countStr = "\(entries.count) entr\(entries.count == 1 ? "y" : "ies")"
        let countFont = UIFont(name: "Georgia", size: Layout.coverMetaSize)
            ?? UIFont.systemFont(ofSize: Layout.coverMetaSize)
        let countAttrs: [NSAttributedString.Key: Any] = [
            .font: countFont,
            .foregroundColor: inkLight
        ]
        let countSize = (countStr as NSString).size(withAttributes: countAttrs)
        (countStr as NSString).draw(
            at: CGPoint(x: centerX - countSize.width / 2, y: y),
            withAttributes: countAttrs
        )

        // Footer
        let footerY = pageRect.height - Layout.marginBottom - 14
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .medium),
            .foregroundColor: inkLight.withAlphaComponent(0.6),
            .kern: 2.0 as NSNumber
        ]
        let footerStr = "SPOTJOURNAL"
        let footerSize = (footerStr as NSString).size(withAttributes: footerAttrs)
        (footerStr as NSString).draw(
            at: CGPoint(x: centerX - footerSize.width / 2, y: footerY),
            withAttributes: footerAttrs
        )
    }

    // MARK: - Entry Pages

    private static func drawEntryPages(
        entry: JournalEntry,
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        captionFont: CaptionFont,
        pageNumber: inout Int
    ) {
        let contentRect = CGRect(
            x: Layout.marginH, y: Layout.marginTop,
            width: Layout.contentWidth, height: Layout.contentHeight
        )

        context.beginPage()
        drawPageNumber(pageNumber, in: pageRect)
        pageNumber += 1

        var cursorY = contentRect.minY

        // Draw photo
        if let image = loadImage(for: entry) {
            let aspect = image.size.width / image.size.height
            var drawWidth = contentRect.width
            var drawHeight = drawWidth / aspect
            if drawHeight > Layout.maxPhotoHeight {
                drawHeight = Layout.maxPhotoHeight
                drawWidth = drawHeight * aspect
            }
            let photoX = contentRect.minX + (contentRect.width - drawWidth) / 2
            image.draw(in: CGRect(x: photoX, y: cursorY, width: drawWidth, height: drawHeight))
            cursorY += drawHeight + Layout.photoCaptionGap
        }

        // Build attributed caption
        let blocks = parseCaptionBlocks(entry.caption)
        let attrCaption = attributedCaption(blocks: blocks, font: captionFont)
        let captionHeight = measureHeight(of: attrCaption, width: contentRect.width)

        // Estimate metadata height
        let metaEstimate: CGFloat = 40 + (entry.tags.isEmpty ? 0 : 28) + (entry.moods.isEmpty ? 0 : 28)
        let spaceOnFirstPage = contentRect.maxY - cursorY

        if captionHeight + metaEstimate + Layout.metaTopPadding <= spaceOnFirstPage {
            // Everything fits on one page
            let captionRect = CGRect(x: contentRect.minX, y: cursorY,
                                     width: contentRect.width, height: captionHeight + 2)
            attrCaption.draw(in: captionRect)
            cursorY += captionHeight + Layout.metaTopPadding
            _ = drawMetadata(entry: entry, at: cursorY, in: contentRect)
        } else {
            // Overflow across pages
            let finalY = drawCaptionWithOverflow(
                attrCaption: attrCaption,
                startY: cursorY,
                contentRect: contentRect,
                context: context,
                pageRect: pageRect,
                pageNumber: &pageNumber
            )
            _ = drawMetadata(entry: entry, at: finalY + Layout.metaTopPadding, in: contentRect)
        }
    }

    // MARK: - Caption Overflow with CTFramesetter

    private static func drawCaptionWithOverflow(
        attrCaption: NSAttributedString,
        startY: CGFloat,
        contentRect: CGRect,
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        pageNumber: inout Int
    ) -> CGFloat {
        let framesetter = CTFramesetterCreateWithAttributedString(attrCaption)
        var charIndex = 0
        let totalLength = attrCaption.length
        var isFirstFrame = true
        var lastFrameBottom: CGFloat = startY

        while charIndex < totalLength {
            let frameY: CGFloat
            let frameHeight: CGFloat

            if isFirstFrame {
                frameY = startY
                frameHeight = contentRect.maxY - startY
                isFirstFrame = false
            } else {
                context.beginPage()
                drawPageNumber(pageNumber, in: pageRect)
                pageNumber += 1
                frameY = contentRect.minY
                frameHeight = contentRect.height
            }

            // Use CTFramesetter to determine how much text fits
            let path = CGPath(rect: CGRect(x: 0, y: 0,
                                           width: contentRect.width,
                                           height: frameHeight), transform: nil)
            let range = CFRange(location: charIndex, length: 0)
            let frame = CTFramesetterCreateFrame(framesetter, range, path, nil)
            let visibleRange = CTFrameGetVisibleStringRange(frame)

            if visibleRange.length == 0 { break }

            // Draw the visible portion
            let subAttr = attrCaption.attributedSubstring(
                from: NSRange(location: charIndex, length: visibleRange.length)
            )
            let subHeight = measureHeight(of: subAttr, width: contentRect.width)
            let drawRect = CGRect(x: contentRect.minX, y: frameY,
                                  width: contentRect.width, height: subHeight + 2)
            subAttr.draw(in: drawRect)

            charIndex += visibleRange.length
            lastFrameBottom = frameY + subHeight
        }

        return lastFrameBottom
    }

    // MARK: - Metadata

    @discardableResult
    private static func drawMetadata(
        entry: JournalEntry,
        at y: CGFloat,
        in contentRect: CGRect
    ) -> CGFloat {
        var currentY = y

        // Hairline rule
        let rulePath = UIBezierPath()
        rulePath.move(to: CGPoint(x: contentRect.minX, y: currentY))
        rulePath.addLine(to: CGPoint(x: contentRect.minX + 80, y: currentY))
        inkLight.withAlphaComponent(0.3).setStroke()
        rulePath.lineWidth = 0.5
        rulePath.stroke()
        currentY += 10

        // Date + Place
        let df = DateFormatter()
        df.dateFormat = "MMMM d, yyyy  \u{00B7}  h:mm a"
        var metaStr = df.string(from: entry.date)
        if !entry.place.isEmpty {
            metaStr += "   \u{00B7}   \(entry.place)"
        }
        let metaFont = UIFont(name: "Georgia", size: Layout.metaFontSize)
            ?? UIFont.systemFont(ofSize: Layout.metaFontSize)
        let metaAttrs: [NSAttributedString.Key: Any] = [
            .font: metaFont,
            .foregroundColor: inkLight
        ]
        let metaRect = CGRect(x: contentRect.minX, y: currentY,
                              width: contentRect.width, height: 40)
        (metaStr as NSString).draw(in: metaRect, withAttributes: metaAttrs)
        currentY += 18

        // Tags
        if !entry.tags.isEmpty {
            currentY += 4
            var tagX = contentRect.minX
            let tagFont = UIFont.systemFont(ofSize: Layout.tagFontSize, weight: .medium)
            let tagAttrs: [NSAttributedString.Key: Any] = [
                .font: tagFont,
                .foregroundColor: inkMedium
            ]

            for tag in entry.tags {
                let tagSize = (tag.name as NSString).size(withAttributes: tagAttrs)
                let chipW = tagSize.width + Layout.tagChipPaddingH * 2
                let chipH = tagSize.height + Layout.tagChipPaddingV * 2

                if tagX + chipW > contentRect.maxX {
                    tagX = contentRect.minX
                    currentY += chipH + 4
                }

                let chipRect = CGRect(x: tagX, y: currentY, width: chipW, height: chipH)
                let chipPath = UIBezierPath(roundedRect: chipRect,
                                            cornerRadius: Layout.tagChipCorner)
                UIColor(red: 0.91, green: 0.88, blue: 0.83, alpha: 1).setFill()
                chipPath.fill()

                (tag.name as NSString).draw(
                    at: CGPoint(x: tagX + Layout.tagChipPaddingH,
                                y: currentY + Layout.tagChipPaddingV),
                    withAttributes: tagAttrs
                )
                tagX += chipW + Layout.tagSpacing
            }
            currentY += 20
        }

        // Moods
        if !entry.moods.isEmpty {
            currentY += 4
            var moodX = contentRect.minX
            let moodFont = UIFont.systemFont(ofSize: Layout.tagFontSize, weight: .medium)
            let moodAttrs: [NSAttributedString.Key: Any] = [
                .font: moodFont,
                .foregroundColor: inkMedium
            ]

            for mood in entry.moods {
                let label = "\(mood.emoji) \(mood.name)"
                let labelSize = (label as NSString).size(withAttributes: moodAttrs)
                let chipW = labelSize.width + Layout.tagChipPaddingH * 2
                let chipH = labelSize.height + Layout.tagChipPaddingV * 2

                if moodX + chipW > contentRect.maxX {
                    moodX = contentRect.minX
                    currentY += chipH + 4
                }

                let chipRect = CGRect(x: moodX, y: currentY, width: chipW, height: chipH)
                let chipPath = UIBezierPath(roundedRect: chipRect,
                                            cornerRadius: Layout.tagChipCorner)
                UIColor(red: 0.94, green: 0.92, blue: 0.88, alpha: 1).setFill()
                chipPath.fill()

                (label as NSString).draw(
                    at: CGPoint(x: moodX + Layout.tagChipPaddingH,
                                y: currentY + Layout.tagChipPaddingV),
                    withAttributes: moodAttrs
                )
                moodX += chipW + Layout.tagSpacing
            }
            currentY += 20
        }

        return currentY
    }

    // MARK: - Helpers

    private static func loadImage(for entry: JournalEntry) -> UIImage? {
        switch entry.photoSource {
        case .placeholder(let key):
            let view = PlaceholderPhoto(photoKey: key).frame(width: 400, height: 400)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2.0
            return renderer.uiImage
        case .file(let filename):
            return PhotoStore.load(filename)
        case .data(let data):
            return UIImage(data: data)
        }
    }

    private static func uiFont(for style: CaptionFont, size: CGFloat) -> UIFont {
        switch style {
        case .serif:
            return UIFont(name: "Georgia", size: size) ?? .systemFont(ofSize: size)
        case .sans:
            return .systemFont(ofSize: size)
        case .hand:
            return UIFont(name: "Bradley Hand", size: size + 4) ?? .systemFont(ofSize: size)
        }
    }

    private static func attributedCaption(
        blocks: [CaptionBlock],
        font style: CaptionFont
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let baseFont = uiFont(for: style, size: Layout.captionFontSize)

        for (index, block) in blocks.enumerated() {
            if index > 0 {
                result.append(NSAttributedString(string: "\n"))
            }

            switch block {
            case .prose(let text):
                let para = NSMutableParagraphStyle()
                para.lineSpacing = Layout.captionLineSpacing
                result.append(NSAttributedString(string: text, attributes: [
                    .font: baseFont,
                    .foregroundColor: inkDark,
                    .paragraphStyle: para
                ]))

            case .bullet(let text):
                let para = NSMutableParagraphStyle()
                para.lineSpacing = Layout.captionLineSpacing
                para.headIndent = Layout.bulletIndent
                let bulletStr = "\u{2022}  \(text)"
                result.append(NSAttributedString(string: bulletStr, attributes: [
                    .font: uiFont(for: style, size: Layout.captionFontSize * 0.92),
                    .foregroundColor: inkDark,
                    .paragraphStyle: para
                ]))

            case .numbered(let n, let text):
                let para = NSMutableParagraphStyle()
                para.lineSpacing = Layout.captionLineSpacing
                para.headIndent = Layout.numberedLabelWidth
                let numStr = "\(n).  \(text)"
                result.append(NSAttributedString(string: numStr, attributes: [
                    .font: uiFont(for: style, size: Layout.captionFontSize * 0.92),
                    .foregroundColor: inkDark,
                    .paragraphStyle: para
                ]))
            }
        }
        return result
    }

    private static func drawPageNumber(_ number: Int, in pageRect: CGRect) {
        let str = "\(number)"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: Layout.pageNumberSize),
            .foregroundColor: inkLight.withAlphaComponent(0.5)
        ]
        let size = (str as NSString).size(withAttributes: attrs)
        (str as NSString).draw(
            at: CGPoint(x: pageRect.midX - size.width / 2,
                        y: pageRect.height - Layout.pageNumberBottom),
            withAttributes: attrs
        )
    }

    private static func measureHeight(of attrString: NSAttributedString, width: CGFloat) -> CGFloat {
        let bounds = attrString.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return ceil(bounds.height)
    }
}
