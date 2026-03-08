import SwiftUI
import Location

@main
struct SampleApp: App {
    @State private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView(locationManager: locationManager)
        }
    }
}
