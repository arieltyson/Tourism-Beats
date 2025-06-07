import MapKit
import SwiftUI

struct MapView: UIViewRepresentable {
    @Binding var selectedCity: CityModel?
    @Binding var showAlert: Bool
    @Binding var region: MKCoordinateRegion
    @Binding var lastRegion: MKCoordinateRegion?
    let cities: [CityModel]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .standard
        mapView.overrideUserInterfaceStyle = .dark
        mapView.setRegion(region, animated: false)

        for city in cities {
            let pin = MKPointAnnotation()
            pin.title = city.name
            pin.coordinate = city.coordinate
            mapView.addAnnotation(pin)
        }
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Only animate if our SwiftUI region actually differs
        if !uiView.region.isApproximatelyEqual(to: region) {
            uiView.setRegion(region, animated: true)
        }

        // Deselect if the user cancelled
        if selectedCity == nil {
            uiView.selectedAnnotations.forEach {
                uiView.deselectAnnotation($0, animated: true)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        // 1) Pin tapped: stash current region, zoom in, fire alert
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard
                let name = view.annotation?.title ?? "",
                let city = parent.cities.first(where: { $0.name == name })
            else { return }

            parent.lastRegion = parent.region
            parent.region = MKCoordinateRegion(
                center: city.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
            )
            parent.selectedCity = city
            parent.showAlert = true
        }

        // 2) User pans/zooms: sync back into SwiftUI state, but only if not mid-alert
        func mapView(
            _ mapView: MKMapView,
            regionDidChangeAnimated animated: Bool
        ) {
            Task {
                // ignore callbacks while we’re still showing the “zoomed in” alert
                guard parent.lastRegion == nil else { return }

                // yield so we don’t mutate state in the middle of MapKit’s update pass
                await Task.yield()

                parent.region = mapView.region
            }
        }
    }
}

// MARK: - Helper Extension

extension MKCoordinateRegion {
    /// Rough comparison to avoid tiny floating-point drifts
    func isApproximatelyEqual(
        to other: MKCoordinateRegion,
        tolerance: Double = 0.000_1
    ) -> Bool {
        abs(center.latitude - other.center.latitude) < tolerance
            && abs(center.longitude - other.center.longitude) < tolerance
            && abs(span.latitudeDelta - other.span.latitudeDelta) < tolerance
            && abs(span.longitudeDelta - other.span.longitudeDelta) < tolerance
    }
}
