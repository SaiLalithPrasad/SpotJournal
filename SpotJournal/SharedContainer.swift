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

    struct PendingEntry: Codable {
        let imageFilename: String
        let date: Date?
        let latitude: Double?
        let longitude: Double?
        let caption: String
    }

    /// Reads and removes all pending shared entries.
    static func consumePending() -> [(data: Data, meta: PendingEntry)] {
        guard let dir = pendingDir,
              FileManager.default.fileExists(atPath: dir.path) else { return [] }

        var results: [(Data, PendingEntry)] = []
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

            let imageFile = dir.appendingPathComponent(meta.imageFilename)
            guard let imageData = try? Data(contentsOf: imageFile) else {
                try? fm.removeItem(at: jsonFile)
                continue
            }

            results.append((imageData, meta))

            // Clean up
            try? fm.removeItem(at: jsonFile)
            try? fm.removeItem(at: imageFile)
        }

        return results
    }
}
