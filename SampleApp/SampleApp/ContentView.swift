import SwiftUI
import CoreLocation
import Location

struct ContentView: View {
    var locationManager: LocationManager

    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Authorization") {
                    LabeledContent("Status", value: statusText)

                    if locationManager.authorizationStatus == .notDetermined {
                        Button("Request Permission") {
                            Task {
                                await locationManager.requestWhenInUseAuthorization()
                            }
                        }
                    }
                }

                if locationManager.isAuthorized {
                    Section("One-Shot Location") {
                        Button("Get Current Location") {
                            Task {
                                do {
                                    _ = try await locationManager.currentLocation()
                                    errorMessage = nil
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        }
                    }

                    Section("Continuous Updates") {
                        LabeledContent("Updating", value: locationManager.isUpdating ? "Yes" : "No")

                        if locationManager.isUpdating {
                            Button("Stop Updates") {
                                locationManager.stopUpdating()
                            }
                        } else {
                            Button("Start Updates") {
                                locationManager.startUpdatingInBackground()
                            }
                        }
                    }
                }

                if let location = locationManager.location {
                    Section("Location") {
                        LabeledContent("Latitude", value: String(format: "%.6f", location.coordinate.latitude))
                        LabeledContent("Longitude", value: String(format: "%.6f", location.coordinate.longitude))
                        LabeledContent("Accuracy", value: String(format: "%.1f m", location.horizontalAccuracy))
                    }
                }

                if let errorMessage {
                    Section("Error") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Location Sample")
        }
    }

    private var statusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined: "Not Determined"
        case .restricted: "Restricted"
        case .denied: "Denied"
        case .authorizedAlways: "Always"
        case .authorizedWhenInUse: "When In Use"
        @unknown default: "Unknown"
        }
    }
}
