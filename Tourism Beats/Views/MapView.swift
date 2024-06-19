//
//  MapView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 17/6/24.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var selectedCity: String?
    @Binding var showAlert: Bool

    private let cities = [
        ("London", CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)),
        ("Paris", CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)),
        ("Tokyo", CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917)),
        ("Berlin", CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050)),
        ("Madrid", CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038)),
        ("Rome", CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964))
    ]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .standard // Use standard map type for night mode
        mapView.overrideUserInterfaceStyle = .dark // Set dark mode

        for city in cities {
            let annotation = MKPointAnnotation()
            annotation.title = city.0
            annotation.coordinate = city.1
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
            if let title = view.annotation?.title ?? nil {
                parent.selectedCity = title
                parent.showAlert = true
            }
        }
    }
}
