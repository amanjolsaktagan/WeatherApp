import Foundation
import CoreLocation

enum LocationError: Error {
    case permissionDenied
    case unavailable
    case cancelled
}

final class LocationService: NSObject, LocationProviding {

    private let manager: CLLocationManager
    private let geocoder = CLGeocoder()
    private let lock = NSLock()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        self.manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestCurrentPlace() async throws -> Place {
        let location = try await requestCurrentLocation()
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        let name = placemarks.first?.locality
            ?? placemarks.first?.name
            ?? "Current Location"
        return Place(
            name: name,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }

    private func requestCurrentLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            installContinuation(continuation)
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied, .restricted:
                resume(.failure(LocationError.permissionDenied))
            @unknown default:
                resume(.failure(LocationError.permissionDenied))
            }
        }
    }

    private func installContinuation(_ continuation: CheckedContinuation<CLLocation, Error>) {
        lock.lock()
        let previous = locationContinuation
        locationContinuation = continuation
        lock.unlock()
        previous?.resume(throwing: LocationError.cancelled)
    }

    private func resume(_ result: Result<CLLocation, Error>) {
        lock.lock()
        let continuation = locationContinuation
        locationContinuation = nil
        lock.unlock()
        continuation?.resume(with: result)
    }
}

extension LocationService: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            resume(.failure(LocationError.permissionDenied))
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            resume(.failure(LocationError.unavailable))
            return
        }
        resume(.success(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        resume(.failure(error))
    }
}
