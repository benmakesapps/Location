import Testing
import Foundation
@testable import Location

@Suite("LocationError")
struct LocationErrorTests {

    @Test func unauthorizedDescription() {
        #expect(LocationError.unauthorized.errorDescription ==
            "Location access is not authorized. Enable it in Settings.")
    }

    @Test func unavailableDescription() {
        #expect(LocationError.unavailable.errorDescription ==
            "Location services are not available on this device.")
    }

    @Test func timeoutDescription() {
        #expect(LocationError.timeout.errorDescription ==
            "Location request timed out.")
    }

    @Test func underlyingDescription() {
        let underlying = NSError(domain: "test", code: 42,
                                 userInfo: [NSLocalizedDescriptionKey: "disk full"])
        #expect(LocationError.underlying(underlying).errorDescription == "disk full")
    }
}
