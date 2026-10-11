import Foundation
import MapKit
import CoreLocation
import SwiftUI

@MainActor
public final class MapManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    public static let shared = MapManager()

    @Published public var userLocation: CLLocationCoordinate2D?
    @Published public var destinationCoordinate: CLLocationCoordinate2D?
    @Published public var destinationName: String = "Home"
    @Published public var homeAddress: String = UserDefaults.standard.string(forKey: "AURA_HOME_ADDRESS") ?? "1 Apple Park Way, Cupertino, CA"
    @Published public var currentRoute: MKRoute?
    @Published public var routeDistance: String = ""
    @Published public var routeETA: String = ""
    @Published public var turnInstructions: [String] = []
    @Published public var isNavigating: Bool = false
    @Published public var region: MKCoordinateRegion?
    @Published public var statusMessage: String = "Ready for navigation"

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        // Default initial region (San Francisco Bay / Silicon Valley)
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        )

        requestLocation()
    }

    public func requestLocation() {
        locationManager.startUpdatingLocation()
    }

    public func setHomeAddress(_ address: String) {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        self.homeAddress = trimmed
        UserDefaults.standard.set(trimmed, forKey: "AURA_HOME_ADDRESS")
    }

    // MARK: - Navigation Intents
    public func navigateHome() async -> CommandResponse {
        let timeStr = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        self.destinationName = "Home"
        return await calculateRoute(to: homeAddress, label: "Home", timeStr: timeStr)
    }

    public func navigateTo(destination: String) async -> CommandResponse {
        let timeStr = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        self.destinationName = destination.capitalized
        return await calculateRoute(to: destination, label: destination.capitalized, timeStr: timeStr)
    }

    private func calculateRoute(to destinationAddress: String, label: String, timeStr: String) async -> CommandResponse {
        self.statusMessage = "Finding route to \(label)..."

        // 1. Geocode Destination
        guard let destPlacemark = try? await geocode(address: destinationAddress) else {
            let errorMsg = "Could not locate address: \"\(destinationAddress)\". Please check location or set Home address."
            return CommandResponse(
                success: false,
                type: "navigation",
                app: "MapKit",
                message: errorMsg,
                speech: "I could not find the location for \(label).",
                timestamp: timeStr,
                command: "navigate to \(label)"
            )
        }

        guard let destCoord = destPlacemark.location?.coordinate else {
            return CommandResponse(
                success: false,
                type: "navigation",
                app: "MapKit",
                message: "Could not retrieve coordinates for \(label).",
                speech: "Could not find coordinates for \(label).",
                timestamp: timeStr,
                command: "navigate to \(label)"
            )
        }
        self.destinationCoordinate = destCoord
        self.destinationName = label

        // 2. Determine Origin (User Location or fallback starting point)
        let originCoord = userLocation ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

        // 3. Compute Directions via MKDirections
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: originCoord))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destCoord))
        request.transportType = .automobile
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)

        do {
            let response = try await directions.calculate()
            if let route = response.routes.first {
                self.currentRoute = route
                let distanceMiles = route.distance / 1609.34
                let etaMins = max(1, Int(round(route.expectedTravelTime / 60.0)))

                self.routeDistance = String(format: "%.1f miles", distanceMiles)
                self.routeETA = "\(etaMins) mins"

                self.turnInstructions = route.steps
                    .map { $0.instructions }
                    .filter { !$0.isEmpty }

                self.isNavigating = true
                self.statusMessage = "Route to \(label): \(self.routeDistance) • \(self.routeETA)"

                // Adjust map region to fit route bounding box
                let rect = route.polyline.boundingMapRect
                self.region = MKCoordinateRegion(rect)

                let speechText = "Plotting route to \(label). Distance is \(self.routeDistance), estimated time \(self.routeETA). Bringing you \(label.lowercased() == "home" ? "home now" : "there now")."
                let displayMsg = "Navigation active: \(self.routeDistance) • \(self.routeETA) to \(label). Next step: \(self.turnInstructions.first ?? "Head toward route")."

                return CommandResponse(
                    success: true,
                    type: "navigation",
                    app: "MapKit",
                    message: displayMsg,
                    speech: speechText,
                    timestamp: timeStr,
                    command: "navigate to \(label)"
                )
            }
        } catch {
            print("[MapManager] Directions calculation error: \(error)")
        }

        // Fallback: Show destination on map without routing polyline
        self.region = MKCoordinateRegion(center: destCoord, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        self.isNavigating = true
        let speechText = "Centered map on \(label). Opening directions."
        return CommandResponse(
            success: true,
            type: "navigation",
            app: "MapKit",
            message: "Located \(label) on map.",
            speech: speechText,
            timestamp: timeStr,
            command: "navigate to \(label)"
        )
    }

    private func geocode(address: String) async throws -> CLPlacemark? {
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.geocodeAddressString(address) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: placemarks?.first)
                }
            }
        }
    }

    public func openInAppleMaps() {
        guard let dest = destinationCoordinate else { return }
        let placemark = MKPlacemark(coordinate: dest)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = destinationName
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    public func openInGoogleMaps() {
        let query = destinationName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Home"
        if let url = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(query)") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - CLLocationManagerDelegate
    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.userLocation = loc.coordinate
            if !self.isNavigating {
                self.region = MKCoordinateRegion(center: loc.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            }
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[MapManager] Location error: \(error)")
    }
}

// MARK: - AppKit / SwiftUI Interactive MapKit View
public struct InteractiveMapView: NSViewRepresentable {
    @ObservedObject var mapManager = MapManager.shared

    public init() {}

    public func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsTraffic = true
        return mapView
    }

    public func updateNSView(_ mapView: MKMapView, context: Context) {
        context.coordinator.update(mapView: mapView, mapManager: mapManager)
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public class Coordinator: NSObject, MKMapViewDelegate {
        private var lastRenderedRoute: MKRoute?

        func update(mapView: MKMapView, mapManager: MapManager) {
            // Update annotations
            mapView.removeAnnotations(mapView.annotations)
            if let dest = mapManager.destinationCoordinate {
                let annotation = MKPointAnnotation()
                annotation.coordinate = dest
                annotation.title = mapManager.destinationName
                annotation.subtitle = mapManager.routeETA.isEmpty ? "Destination" : "\(mapManager.routeETA) • \(mapManager.routeDistance)"
                mapView.addAnnotation(annotation)
            }

            // Update route polyline
            if let route = mapManager.currentRoute {
                if lastRenderedRoute != route {
                    mapView.removeOverlays(mapView.overlays)
                    mapView.addOverlay(route.polyline, level: .aboveRoads)
                    mapView.setVisibleMapRect(
                        route.polyline.boundingMapRect,
                        edgePadding: NSEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
                        animated: true
                    )
                    lastRenderedRoute = route
                }
            } else if let region = mapManager.region {
                mapView.setRegion(region, animated: true)
            }
        }

        public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = NSColor(calibratedRed: 0.0, green: 0.85, blue: 1.0, alpha: 0.95)
                renderer.lineWidth = 6.0
                renderer.lineJoin = .round
                renderer.lineCap = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
