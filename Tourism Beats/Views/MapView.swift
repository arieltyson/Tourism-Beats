import MapKit
import SwiftUI

// MARK: - MapView

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
        mapView.setRegion(self.region, animated: false)

        for city in self.cities {
            let pin = MKPointAnnotation()
            pin.title = city.name
            pin.coordinate = city.coordinate
            mapView.addAnnotation(pin)
        }
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context _: Context) {
        // Only animate if our SwiftUI region actually differs
        if !uiView.region.isApproximatelyEqual(to: self.region) {
            uiView.setRegion(self.region, animated: true)
        }

        // Deselect if the user cancelled
        if self.selectedCity == nil {
            for selectedAnnotation in uiView.selectedAnnotations {
                uiView.deselectAnnotation(selectedAnnotation, animated: true)
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
        func mapView(_: MKMapView, didSelect view: MKAnnotationView) {
            guard
                let name = view.annotation?.title ?? "",
                let city = parent.cities.first(where: { $0.name == name })
            else { return }

            self.parent.lastRegion = self.parent.region
            self.parent.region = MKCoordinateRegion(
                center: city.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
            )
            self.parent.selectedCity = city
            self.parent.showAlert = true
        }

        // 2) User pans/zooms: sync back into SwiftUI state, but only if not mid-alert
        func mapView(
            _ mapView: MKMapView,
            regionDidChangeAnimated _: Bool
        ) {
            Task {
                // ignore callbacks while we’re still showing the “zoomed in” alert
                guard self.parent.lastRegion == nil else { return }

                // yield so we don’t mutate state in the middle of MapKit’s update pass
                await Task.yield()

                self.parent.region = mapView.region
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
