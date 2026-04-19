import ImageIO
import CoreLocation
import MapKit

/// Extracts EXIF date and GPS from photo data, and reverse geocodes coordinates.
enum PhotoMetadata {
    struct Result {
        var date: Date?
        var latitude: Double?
        var longitude: Double?
    }

    static func extract(from data: Data) -> Result {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return Result()
        }

        var result = Result()

        // Date from EXIF
        if let exif = props[kCGImagePropertyExifDictionary as String] as? [String: Any],
           let dateString = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
            result.date = formatter.date(from: dateString)
        }

        // GPS coordinates
        if let gps = props[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
            if let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double,
               let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String {
                result.latitude = latRef == "S" ? -lat : lat
            }
            if let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double,
               let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String {
                result.longitude = lonRef == "W" ? -lon : lon
            }
        }

        return result
    }

    static func reverseGeocode(latitude: Double, longitude: Double) async -> String {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else { return "" }
        do {
            let items = try await request.mapItems
            if let item = items.first {
                return readablePlace(from: item)
            }
        } catch {}
        return ""
    }

    static func readablePlace(from item: MKMapItem) -> String {
        if let name = item.name, !name.isEmpty {
            return name
        }
        if let city = item.addressRepresentations?.cityWithContext(.short) {
            return city
        }
        if let city = item.addressRepresentations?.cityName {
            return city
        }
        if let short = item.address?.shortAddress {
            return short
        }
        return ""
    }
}
