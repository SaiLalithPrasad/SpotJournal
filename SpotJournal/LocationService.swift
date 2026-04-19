import CoreLocation
import MapKit

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    var currentPlace: String = ""
    private let manager = CLLocationManager()
    private var lastGeocodedLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            await self.reverseGeocode(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silently ignore — place will stay empty
    }

    // MARK: - Reverse Geocoding

    private func reverseGeocode(_ location: CLLocation) async {
        // Skip if we already have a place and haven't moved much
        if let last = lastGeocodedLocation, !currentPlace.isEmpty,
           location.distance(from: last) < 100 {
            return
        }
        lastGeocodedLocation = location

        guard let request = MKReverseGeocodingRequest(location: location) else { return }
        do {
            let items = try await request.mapItems
            if let item = items.first {
                currentPlace = readablePlace(from: item)
            }
        } catch {
            // Keep whatever we had
        }
    }

    private func readablePlace(from item: MKMapItem) -> String {
        PhotoMetadata.readablePlace(from: item)
    }
}
