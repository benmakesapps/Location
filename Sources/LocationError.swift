import Foundation

public enum LocationError: LocalizedError {
    /// The user has denied or restricted location access.
    case unauthorized

    /// Location services are disabled system-wide.
    case unavailable

    /// A location update was not received within the expected time.
    case timeout

    /// CoreLocation returned an error.
    case underlying(Error)

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            "Location access is not authorized. Enable it in Settings."
        case .unavailable:
            "Location services are not available on this device."
        case .timeout:
            "Location request timed out."
        case .underlying(let error):
            error.localizedDescription
        }
    }
}

extension LocationError: Equatable {
    public static func == (lhs: LocationError, rhs: LocationError) -> Bool {
        switch (lhs, rhs) {
        case (.unauthorized, .unauthorized): true
        case (.unavailable, .unavailable): true
        case (.timeout, .timeout): true
        case (.underlying(let l), .underlying(let r)): l.localizedDescription == r.localizedDescription
        default: false
        }
    }
}
