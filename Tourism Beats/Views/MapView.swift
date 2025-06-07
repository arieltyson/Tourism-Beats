import MapKit
import SwiftUI

struct MapView: UIViewRepresentable {
    @Binding var selectedCity: CityModel?
    @Binding var showAlert: Bool
    let cities: [CityModel]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .standard
        mapView.overrideUserInterfaceStyle = .dark

        let europeCenter = CLLocationCoordinate2D(
            latitude: 54.5260,
            longitude: 15.2551
        )
        let span = MKCoordinateSpan(latitudeDelta: 20.0, longitudeDelta: 20.0)
        mapView.setRegion(
            .init(center: europeCenter, span: span),
            animated: false
        )

        for city in cities {
            let annotation = MKPointAnnotation()
            annotation.title = city.name
            annotation.coordinate = city.coordinate
            mapView.addAnnotation(annotation)
        }

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if selectedCity == nil {
            uiView.selectedAnnotations.forEach {
                uiView.deselectAnnotation($0, animated: true)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        init(_ parent: MapView) { self.parent = parent }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard
                let title = view.annotation?.title ?? "",
                let city = parent.cities.first(where: { $0.name == title })
            else { return }

            parent.selectedCity = city
            parent.showAlert = true
        }
    }
}
