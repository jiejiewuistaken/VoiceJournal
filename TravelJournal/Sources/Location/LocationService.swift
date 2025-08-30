import Foundation
import CoreLocation

public protocol LocationServiceDelegate: AnyObject {
    func locationServiceDidUpdate(_ service: LocationService, location: CLLocation)
    func locationService(_ service: LocationService, didFail error: Error)
}

public final class LocationService: NSObject {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    public weak var delegate: LocationServiceDelegate?

    public private(set) var lastLocation: CLLocation?
    public private(set) var lastPlacemarkDescription: String?

    public override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 10
    }

    public func requestAuthorization() {
        if CLLocationManager.authorizationStatus() == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    public func start() {
        manager.startUpdatingLocation()
    }

    public func stop() {
        manager.stopUpdatingLocation()
    }

    public func reverseGeocodeIfNeeded(for location: CLLocation, completion: @escaping (String?) -> Void) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            if let error = error {
                self.delegate?.locationService(self, didFail: error)
                completion(nil)
                return
            }
            let desc = LocationService.composePlacemarkDescription(placemarks?.first)
            self.lastPlacemarkDescription = desc
            completion(desc)
        }
    }

    public static func composePlacemarkDescription(_ placemark: CLPlacemark?) -> String? {
        guard let p = placemark else { return nil }
        let parts: [String] = [
            p.name,
            p.locality,
            p.subLocality,
            p.administrativeArea,
            p.country
        ].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.joined(separator: ", ")
    }
}

extension LocationService: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            break
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        delegate?.locationServiceDidUpdate(self, location: location)
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.locationService(self, didFail: error)
    }
}

