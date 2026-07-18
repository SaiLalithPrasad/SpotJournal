import Foundation

/// Shared data exchange between the main app and the share extension.
/// Both targets must have the same App Group capability enabled.
enum SharedContainer {
    static let appGroupID = "group.spotjournal.shared"

    static var pendingDir: URL? {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else { return nil }
        return container.appendingPathComponent("pending", isDirectory: true)
    }

    struct PendingEntry: Decodable {
        let imageFilenames: [String]
        let date: Date?
        let latitude: Double?
        let longitude: Double?
        let caption: String

        enum CodingKeys: String, CodingKey {
            case imageFilenames, imageFilename, date, latitude, longitude, caption
        }

        init(imageFilenames: [String], date: Date?, latitude: Double?, longitude: Double?, caption: String) {
            self.imageFilenames = imageFilenames
            self.date = date
            self.latitude = latitude
            self.longitude = longitude
            self.caption = caption
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            // Accept the new array field, or fall back to a legacy single filename.
            if let arr = try c.decodeIfPresent([String].self, forKey: .imageFilenames) {
                imageFilenames = arr
            } else if let single = try c.decodeIfPresent(String.self, forKey: .imageFilename) {
                imageFilenames = [single]
            } else {
                imageFilenames = []
            }
            date = try c.decodeIfPresent(Date.self, forKey: .date)
            latitude = try c.decodeIfPresent(Double.self, forKey: .latitude)
            longitude = try c.decodeIfPresent(Double.self, forKey: .longitude)
            caption = try c.decodeIfPresent(String.self, forKey: .caption) ?? ""
        }
    }

    /// Reads and removes all pending shared entries.
    static func consumePending() -> [(images: [Data], meta: PendingEntry)] {
        guard let dir = pendingDir,
              FileManager.default.fileExists(atPath: dir.path) else { return [] }

        var results: [(images: [Data], meta: PendingEntry)] = []
        let fm = FileManager.default

        guard let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            return []
        }

        let jsonFiles = files.filter { $0.pathExtension == "json" }
        for jsonFile in jsonFiles {
            guard let jsonData = try? Data(contentsOf: jsonFile),
                  let meta = try? JSONDecoder().decode(PendingEntry.self, from: jsonData) else {
                try? fm.removeItem(at: jsonFile)
                continue
            }

            let images = meta.imageFilenames.compactMap { name -> Data? in
                try? Data(contentsOf: dir.appendingPathComponent(name))
            }

            // Clean up files regardless
            try? fm.removeItem(at: jsonFile)
            for name in meta.imageFilenames {
                try? fm.removeItem(at: dir.appendingPathComponent(name))
            }

            guard !images.isEmpty else { continue }
            results.append((images, meta))
        }

        return results
    }
}
