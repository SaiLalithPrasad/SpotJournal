import UIKit
import ImageIO

enum PhotoStore {
    private static var photosDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Photos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Returns the thumbnail filename for a given original filename.
    private static func thumbnailFilename(for original: String) -> String {
        "THUMB_\(original)"
    }

    /// Generate a thumbnail file on disk for the given filename.
    /// Uses CGImageSource for efficient downsampling without decoding the full image.
    @discardableResult
    static func generateThumbnail(for filename: String, maxPixelSize: CGFloat = 300) -> Bool {
        let sourceURL = photosDirectory.appendingPathComponent(filename)
        guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil) else { return false }

        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return false
        }

        // Redraw into an opaque context to strip alpha (avoids CoreGraphics warning)
        let w = cgImage.width, h = cgImage.height
        guard let ctx = CGContext(
            data: nil, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return false }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        guard let opaqueImage = ctx.makeImage() else { return false }

        let thumbURL = photosDirectory.appendingPathComponent(thumbnailFilename(for: filename))
        let uiImage = UIImage(cgImage: opaqueImage)
        guard let jpegData = uiImage.jpegData(compressionQuality: 0.7) else { return false }
        do {
            try jpegData.write(to: thumbURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    /// Save JPEG data, returns the filename (not full path)
    static func save(_ imageData: Data) throws -> String {
        let filename = "IMG_\(Int(Date().timeIntervalSince1970))_\(UInt32.random(in: 0...9999)).jpg"
        let url = photosDirectory.appendingPathComponent(filename)
        try imageData.write(to: url, options: .atomic)
        generateThumbnail(for: filename)
        return filename
    }

    /// Load a UIImage by filename
    static func load(_ filename: String) -> UIImage? {
        let url = photosDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Load a thumbnail UIImage by filename.
    /// Falls back to loading the full image if no thumbnail exists.
    static func loadThumbnail(_ filename: String) -> UIImage? {
        let thumbURL = photosDirectory.appendingPathComponent(thumbnailFilename(for: filename))
        if let data = try? Data(contentsOf: thumbURL), let image = UIImage(data: data) {
            return image
        }
        return load(filename)
    }

    /// Load raw file data by filename (for export)
    static func loadData(_ filename: String) -> Data? {
        let url = photosDirectory.appendingPathComponent(filename)
        return try? Data(contentsOf: url)
    }

    /// Delete a photo file and its thumbnail
    static func delete(_ filename: String) {
        let url = photosDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
        let thumbURL = photosDirectory.appendingPathComponent(thumbnailFilename(for: filename))
        try? FileManager.default.removeItem(at: thumbURL)
    }
}
