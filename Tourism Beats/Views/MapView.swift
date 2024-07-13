//
//  MapView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 17/6/24.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var selectedCity: City?
    @Binding var showAlert: Bool

    private let cities = CityData.cities

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .standard
        mapView.overrideUserInterfaceStyle = .dark

        let europeCenter = CLLocationCoordinate2D(latitude: 54.5260, longitude: 15.2551)
                let span = MKCoordinateSpan(latitudeDelta: 20.0, longitudeDelta: 20.0)
                let region = MKCoordinateRegion(center: europeCenter, span: span)
                mapView.setRegion(region, animated: false)

        for city in cities {
            let annotation = MKPointAnnotation()
            annotation.title = city.name
            annotation.coordinate = city.coordinate
            mapView.addAnnotation(annotation)
        }

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let title = view.annotation?.title ?? "" ,
               let city = parent.cities.first(where: {$0.name == title }) {
                parent.selectedCity = city
                parent.showAlert = true
            }
        }
    }
}

extension City {
    var coordinate: CLLocationCoordinate2D {
        switch self.name {
        case "London": return CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
        case "Paris": return CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        case "Tokyo": return CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917)
        case "Berlin": return CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050)
        case "Barcelona": return CLLocationCoordinate2D(latitude: 41.3851, longitude: 2.1734)
        case "Rome": return CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964)
        case "Beijing": return CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)
        case "Cairo": return CLLocationCoordinate2D(latitude: 30.0444, longitude: 31.2357)
        case "New Delhi": return CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090)
        case "Rio De Janeiro": return CLLocationCoordinate2D(latitude: -22.9068, longitude: -43.1729)
        case "Moscow": return CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6176)
        case "Amsterdam": return CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041)
        case "Athens": return CLLocationCoordinate2D(latitude: 37.9838, longitude: 23.7275)
        case "Bangkok": return CLLocationCoordinate2D(latitude: 13.7563, longitude: 100.5018)
        default: return CLLocationCoordinate2D()
        }
    }
}
