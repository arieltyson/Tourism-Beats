// WorldView.swift
// Tourism Beats
//
// Map-based city exploration with a search bar floating within
// thumb reach, following Apple Human Interface Guidelines.

import MapKit
import SwiftUI

// MARK: - WorldView

struct WorldView: View {
    let onCitySelected: (CityModel) -> Void

    // MARK: Map state

    @State private var selectedCity: CityModel?
    @State private var showAlert = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 140, longitudeDelta: 180)
    )
    @State private var lastRegion: MKCoordinateRegion?
    @State private var alertTimeoutTask: Task<Void, Never>?
    @State private var lastVisitedCoordinate: CLLocationCoordinate2D?

    // MARK: Search state

    @State private var isSearchPresented = false
    @State private var searchBarHeight: CGFloat = 0
    @Namespace private var searchTransition

    private let cities: [CityModel]

    init(onCitySelected: @escaping (CityModel) -> Void) {
        self.onCitySelected = onCitySelected
        self.cities = (try? DataService().loadCities()) ?? []
    }

    var body: some View {
        MapView(
            selectedCity: self.$selectedCity,
            showAlert: self.$showAlert,
            region: self.$region,
            lastRegion: self.$lastRegion,
            cities: self.cities,
            bottomOverlayHeight: self.searchBarHeight,
            onCitySelected: { _ in }
        )
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom) {
            MapSearchBar {
                self.isSearchPresented = true
            }
            .matchedTransitionSource(id: Self.searchTransitionID, in: self.searchTransition)
            .padding(.horizontal, SpacingTokens.medium)
            .padding(.bottom, SpacingTokens.xSmall)
            .onGeometryChange(for: CGFloat.self, of: \.size.height) { height in
                self.searchBarHeight = height
            }
        }
        .navigationTitle("Explore")
        // MapKit blurs the map beneath any navigation bar, so the map
        // screen goes without one and floats its search bar instead.
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: self.$isSearchPresented) {
            CitySearchView(cities: self.cities) { city in
                self.isSearchPresented = false
                self.navigateToCity(city)
            }
            .navigationTransition(
                .zoom(sourceID: Self.searchTransitionID, in: self.searchTransition)
            )
        }
        .onAppear {
            self.zoomOutOnReturn()
            self.resetState()
        }
        .onDisappear {
            self.resetState()
        }
        .onChange(of: self.showAlert) { _, newValue in
            self.handleAlertVisibilityChange(newValue)
        }
        .alert(
            "Explore \(self.selectedCity?.name ?? "")?",
            isPresented: self.$showAlert
        ) {
            Button("Yes") {
                if let city = self.selectedCity {
                    self.lastVisitedCoordinate = city.coordinate
                    self.onCitySelected(city)
                }
                self.clearSelectionState()
            }
            Button("Cancel", role: .cancel) {
                self.region = self.lastRegion ?? self.region
                self.clearSelectionState()
            }
        } message: {
            if let city = self.selectedCity {
                Text("Would you like to explore \(city.name), \(city.country.name)?")
            }
        }
    }

    // MARK: - Search

    private static let searchTransitionID = "search"

    // MARK: - Navigation

    private func navigateToCity(_ city: CityModel) {
        self.lastVisitedCoordinate = city.coordinate
        self.region = MKCoordinateRegion(
            center: city.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
        )
        self.selectedCity = city
        self.onCitySelected(city)
    }

    // MARK: - State Management

    private func zoomOutOnReturn() {
        guard let coordinate = self.lastVisitedCoordinate else { return }
        self.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
        )
    }

    private func resetState() {
        self.selectedCity = nil
        self.showAlert = false
        self.lastRegion = nil
        self.alertTimeoutTask?.cancel()
    }

    private func clearSelectionState() {
        self.selectedCity = nil
        self.showAlert = false
        self.lastRegion = nil
    }

    private func handleAlertVisibilityChange(_ isVisible: Bool) {
        if isVisible {
            self.alertTimeoutTask = Task {
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled else { return }
                self.showAlert = false
                self.selectedCity = nil
                self.lastRegion = nil
            }
        } else {
            self.alertTimeoutTask?.cancel()
        }
    }
}
