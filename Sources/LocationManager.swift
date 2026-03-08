import CoreLocation
import os

/// Provides reactive location state and async methods for requesting
/// the user's location.
///
/// Create a single instance and inject it into the SwiftUI environment.
/// All published properties update on the main actor so they are safe
/// to read from views.
///
/// ## Info.plist Keys
///
/// Your app's `Info.plist` must include at least one of:
///
/// | Key | When to use |
/// |-----|-------------|
/// | `NSLocationWhenInUseUsageDescription` | Required for foreground-only access. Most apps need only this. |
/// | `NSLocationAlwaysAndWhenInUseUsageDescription` | Required if you request "Always" authorization for background location. |
///
/// For background location, also add the `location` background mode
///
@MainActor
@Observable
public final class LocationManager: LocationManagerProtocol {

    // MARK: - Reactive State

    /// The most recent authorization status.
    ///
    /// Observe this property to react to permission changes.
    public private(set) var authorizationStatus: CLAuthorizationStatus

    /// The most recently received location, or `nil` if no location
    /// has been obtained yet.
    ///
    /// Updates automatically while ``startUpdating()`` is active,
    /// or after a successful ``currentLocation()`` call.
    public private(set) var location: CLLocation?

    /// Whether the user has granted at least "When In Use" authorization.
    public var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse
            || authorizationStatus == .authorizedAlways
    }

    /// Whether location updates are currently being streamed.
    public private(set) var isUpdating: Bool = false

    // MARK: - Private

    private let manager: CLLocationManager
    private let delegate: AuthorizationDelegate
    private var updateTask: Task<Void, Never>?
    private var serviceSession: CLServiceSession?
    private var authorizationContinuation: CheckedContinuation<Void, Never>?
    private let logger = Logger(subsystem: "Location", category: "LocationManager")

    // MARK: - Init

    /// Creates a new location manager.
    ///
    /// Reads the initial authorization status from `CLLocationManager`.
    /// No permissions are requested until you call
    /// ``requestWhenInUseAuthorization()`` or begin location updates.
    public init() {
        let manager = CLLocationManager()
        let delegate = AuthorizationDelegate()

        self.manager = manager
        self.delegate = delegate

        self.authorizationStatus = manager.authorizationStatus
        delegate.onAuthorizationChange = { [weak self] in
            guard let self else { return }
            self.refreshAuthorizationStatus()
            self.authorizationContinuation?.resume()
        }
        manager.delegate = delegate
    }

    // MARK: - Authorization

    /// Requests "When In Use" location permission.
    ///
    /// Uses `CLServiceSession` which declaratively maintains
    /// authorization for the lifetime of the session. The system
    /// prompt appears only if the current status is `.notDetermined`.
    ///
    public func requestWhenInUseAuthorization() async {
        manager.requestWhenInUseAuthorization()
        await withCheckedContinuation { continuation in
            self.authorizationContinuation = continuation
        }
        refreshAuthorizationStatus()
    }

    /// Requests "Always" location permission.
    ///
    /// Enables background location updates. The user may see two
    /// prompts: one for "When In Use" and a follow-up for "Always".
    ///
    /// Requires `NSLocationAlwaysAndWhenInUseUsageDescription` in
    /// Info.plist and the `location` background mode.
    ///
    public func requestAlwaysAuthorization() async {
        manager.requestAlwaysAuthorization()
        await withCheckedContinuation { continuation in
            self.authorizationContinuation = continuation
        }
        refreshAuthorizationStatus()
    }

    // MARK: - One-Shot Location

    /// Returns the current device location.
    ///
    /// Iterates `CLLocationUpdate.liveUpdates()` and returns the
    /// first valid location. Throws if the user has not authorized
    /// location access or if services are unavailable.
    ///
    /// You must call ``requestWhenInUseAuthorization()`` (or
    /// ``requestAlwaysAuthorization()``) and wait for ``isAuthorized``
    /// to become `true` before calling this method.
    ///
    public func currentLocation() async throws -> CLLocation {
        guard isAuthorized else {
            throw LocationError.unauthorized
        }

        for try await update in CLLocationUpdate.liveUpdates() {
            if let loc = update.location {
                self.location = loc
                return loc
            }
        }

        throw LocationError.unavailable
    }

    // MARK: - Continuous Updates

    /// Begins streaming location updates into the ``location`` property.
    ///
    /// Updates continue until you call ``stopUpdating()`` or the
    /// enclosing `Task` is cancelled. Designed for use with SwiftUI's
    /// `.task` modifier — cancellation is handled automatically.
    ///
    public func startUpdating() async {
        guard !isUpdating else { return }
        isUpdating = true

        serviceSession = CLServiceSession(authorization: .whenInUse)

        do {
            for try await update in CLLocationUpdate.liveUpdates() {
                guard !Task.isCancelled else { break }
                refreshAuthorizationStatus()

                if let loc = update.location {
                    self.location = loc
                }
            }
        } catch {
            logger.error("Location updates failed: \(error.localizedDescription)")
        }

        isUpdating = false
    }

    /// Stops the current location update stream.
    ///
    /// If updates were started with ``startUpdatingInBackground()``,
    /// this cancels the internal task. If started via a `.task`
    /// modifier, prefer letting SwiftUI cancel the task naturally.
    ///
    public func stopUpdating() {
        updateTask?.cancel()
        updateTask = nil
        serviceSession = nil
        isUpdating = false
    }

    /// Starts location updates in a fire-and-forget task.
    ///
    /// Unlike ``startUpdating()`` (which is `async` and meant for
    /// `.task` modifiers), this launches updates immediately.
    /// Stop with ``stopUpdating()``.
    ///
    public func startUpdatingInBackground() {
        guard !isUpdating else { return }
        updateTask = Task { await startUpdating() }
    }

    // MARK: - Location Stream

    /// Returns an `AsyncStream` of locations for custom iteration.
    ///
    /// Use this when you need fine-grained control over each update,
    /// such as filtering by accuracy or accumulating a track.
    ///
    public func locationStream() -> AsyncStream<CLLocation> {
        AsyncStream { continuation in
            let task = Task {
                let session = CLServiceSession(authorization: .whenInUse)
                defer { _ = session }

                do {
                    for try await update in CLLocationUpdate.liveUpdates() {
                        guard !Task.isCancelled else { break }
                        if let loc = update.location {
                            continuation.yield(loc)
                        }
                    }
                } catch {
                    logger.error("Location stream error: \(error.localizedDescription)")
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Utilities

    /// Returns the distance in meters between the current location and
    /// a target coordinate, or `nil` if no current location is available.
    ///
    public func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        location?.distance(from: CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        ))
    }

    // MARK: - Private

    private func refreshAuthorizationStatus() {
        let newStatus = manager.authorizationStatus
        if authorizationStatus != newStatus {
            authorizationStatus = newStatus
        }
    }
}

// MARK: - Authorization Delegate

private final class AuthorizationDelegate: NSObject, CLLocationManagerDelegate {
    var onAuthorizationChange: (() -> Void)?

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onAuthorizationChange?()
    }
}
