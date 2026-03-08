import CoreLocation

@MainActor
public protocol LocationManagerProtocol {
    /// The most recent authorization status.
    var authorizationStatus: CLAuthorizationStatus { get }

    /// The most recently received location, or `nil` if unavailable.
    var location: CLLocation? { get }

    /// Whether the user has granted at least "When In Use" authorization.
    var isAuthorized: Bool { get }

    /// Whether location updates are currently being streamed.
    var isUpdating: Bool { get }

    /// Requests "When In Use" location permission.
    func requestWhenInUseAuthorization()

    /// Requests "Always" location permission.
    func requestAlwaysAuthorization()

    /// Returns the current device location (one-shot).
    func currentLocation() async throws -> CLLocation

    /// Begins streaming location updates into the ``location`` property.
    func startUpdating() async

    /// Stops the current location update stream.
    func stopUpdating()

    /// Starts location updates in a fire-and-forget task.
    func startUpdatingInBackground()

    /// Returns an `AsyncStream` of locations for custom iteration.
    func locationStream() -> AsyncStream<CLLocation>

    /// Returns the distance in meters from the current location to a coordinate.
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance?
}
