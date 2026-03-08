//
//  LocationManagerProtocolTests.swift
//  Location
//
//  Created by Benjamin Kelsey on 3/7/26.
//

import Testing
import CoreLocation
@testable import Location

@Suite("LocationManagerProtocol")
@MainActor
struct LocationManagerProtocolTests {

    @Test func isAuthorizedWhenInUse() {
        var mock = MockLocationManager()
        mock.authorizationStatus = .authorizedWhenInUse
        #expect(mock.isAuthorized == true)
    }

    @Test func isAuthorizedAlways() {
        var mock = MockLocationManager()
        mock.authorizationStatus = .authorizedAlways
        #expect(mock.isAuthorized == true)
    }

    @Test func isNotAuthorizedWhenDenied() {
        var mock = MockLocationManager()
        mock.authorizationStatus = .denied
        #expect(mock.isAuthorized == false)
    }

    @Test func isNotAuthorizedWhenNotDetermined() {
        let mock = MockLocationManager()
        #expect(mock.isAuthorized == false)
    }

    @Test func distanceReturnsNilWithNoLocation() {
        let mock = MockLocationManager()
        let apple = CLLocationCoordinate2D(latitude: 37.3318, longitude: -122.0312)
        #expect(mock.distance(to: apple) == nil)
    }

    @Test func distanceCalculation() {
        var mock = MockLocationManager()
        // 1 Infinite Loop, Cupertino — roughly 500m from Apple Park
        mock.location = CLLocation(latitude: 37.3318, longitude: -122.0312)
        let applePark = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
        let meters = mock.distance(to: applePark)
        #expect(meters != nil)
        // Rough sanity check — should be between 1km and 3km
        if let meters {
            #expect(meters > 1_000)
            #expect(meters < 3_000)
        }
    }

    @Test func currentLocationThrowsWhenNil() async {
        let mock = MockLocationManager()
        await #expect(throws: LocationError.unavailable) {
            try await mock.currentLocation()
        }
    }

    @Test func currentLocationReturnsWhenSet() async throws {
        var mock = MockLocationManager()
        let expected = CLLocation(latitude: 51.5074, longitude: -0.1278)
        mock.location = expected
        let result = try await mock.currentLocation()
        #expect(result.coordinate.latitude == expected.coordinate.latitude)
        #expect(result.coordinate.longitude == expected.coordinate.longitude)
    }
}
