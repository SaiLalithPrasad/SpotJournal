import UIKit

/// A simple in-memory cache for thumbnail images, keyed by filename.
/// Uses NSCache so the system can evict entries under memory pressure.
final class ThumbnailCache: @unchecked Sendable {
    static let shared = ThumbnailCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 100
    }

    func image(for filename: String) -> UIImage? {
        cache.object(forKey: filename as NSString)
    }

    func setImage(_ image: UIImage, for filename: String) {
        cache.setObject(image, forKey: filename as NSString)
    }
}
