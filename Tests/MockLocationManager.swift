//
//  MockLocationManager.swift
//  Location
//
//  Created by Benjamin Kelsey on 3/7/26.
//

import CoreLocation
@testable import Location

@MainActor
struct MockLocationManager: LocationManagerProtocol {
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var location: CLLocation? = nil
    var isUpdating: Bool = false

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse
            || authorizationStatus == .authorizedAlways
    }

    func requestWhenInUseAuthorization() {}
    func requestAlwaysAuthorization() {}
    func startUpdating() async {}
    func stopUpdating() {}
    func startUpdatingInBackground() {}
    func locationStream() -> AsyncStream<CLLocation> { AsyncStream { $0.finish() } }

    func currentLocation() async throws -> CLLocation {
        guard let location else { throw LocationError.unavailable }
        return location
    }

    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        location?.distance(from: CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        ))
    }
}
