import MapKit
import SwiftUI

// MARK: - MapView

struct MapView: UIViewRepresentable {
    @Binding var selectedCity: CityModel?
    @Binding var showAlert: Bool
    @Binding var region: MKCoordinateRegion
    @Binding var lastRegion: MKCoordinateRegion?
    let cities: [CityModel]
    let onCitySelected: (CityModel) -> Void

    // Build a name → city dictionary once for fast selection.
    private let cityByName: [String: CityModel]

    init(
        selectedCity: Binding<CityModel?>,
        showAlert: Binding<Bool>,
        region: Binding<MKCoordinateRegion>,
        lastRegion: Binding<MKCoordinateRegion?>,
        cities: [CityModel],
        onCitySelected: @escaping (CityModel) -> Void
    ) {
        _selectedCity = selectedCity
        _showAlert = showAlert
        _region = region
        _lastRegion = lastRegion
        self.cities = cities
        self.onCitySelected = onCitySelected
        self.cityByName = Dictionary(
            uniqueKeysWithValues: cities.map { ($0.name, $0) }
        )
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.preferredConfiguration = MKStandardMapConfiguration(emphasisStyle: .muted)
        mapView.overrideUserInterfaceStyle = .dark
        mapView.setRegion(self.region, animated: false)

        // Add all pins
        for city in self.cities {
            let pin = MKPointAnnotation()
            pin.title = city.name
            pin.coordinate = city.coordinate
            mapView.addAnnotation(pin)
        }
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context _: Context) {
        if !uiView.region.isApproximatelyEqual(to: self.region) {
            uiView.setRegion(self.region, animated: true)
        }

        if self.selectedCity == nil, !self.showAlert,
           !uiView.selectedAnnotations.isEmpty
        {
            for selectedAnnotation in uiView.selectedAnnotations {
                uiView.deselectAnnotation(selectedAnnotation, animated: true)
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    @MainActor
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        init(_ parent: MapView) { self.parent = parent }

        func mapView(_: MKMapView, didSelect view: MKAnnotationView) {
            guard
                let titleProvider = view.annotation?.title, // String??
                let name = titleProvider,
                let city = parent.cityByName[name]
            else { return }

            self.parent.lastRegion = self.parent.region
            self.parent.region = MKCoordinateRegion(
                center: city.coordinate,
                span: .init(latitudeDelta: 2, longitudeDelta: 2)
            )
            self.parent.selectedCity = city
            self.parent.showAlert = true
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated _: Bool) {
            Task { @MainActor in
                guard self.parent.lastRegion == nil else { return }
                guard !self.parent.showAlert else { return }
                await Task.yield()
                self.parent.region = mapView.region
            }
        }
    }
}

extension MKCoordinateRegion {
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
