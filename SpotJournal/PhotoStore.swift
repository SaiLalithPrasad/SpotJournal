import UIKit

enum PhotoStore {
    private static var photosDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Photos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Save JPEG data, returns the filename (not full path)
    static func save(_ imageData: Data) throws -> String {
        let filename = "IMG_\(Int(Date().timeIntervalSince1970))_\(UInt32.random(in: 0...9999)).jpg"
        let url = photosDirectory.appendingPathComponent(filename)
        try imageData.write(to: url, options: .atomic)
        return filename
    }

    /// Load a UIImage by filename
    static func load(_ filename: String) -> UIImage? {
        let url = photosDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Load raw file data by filename (for export)
    static func loadData(_ filename: String) -> Data? {
        let url = photosDirectory.appendingPathComponent(filename)
        return try? Data(contentsOf: url)
    }

    /// Delete a photo file
    static func delete(_ filename: String) {
        let url = photosDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }
}
