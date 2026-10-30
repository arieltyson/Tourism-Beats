// WorldView.swift
// Tourism Beats
//
// Map-based city exploration with a search field floating within
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

    @State private var searchViewModel: CitySearchViewModel
    @State private var isSearching = false
    @FocusState private var isSearchFocused: Bool
    @State private var searchFieldHeight: CGFloat = 0

    private let cities: [CityModel]

    init(onCitySelected: @escaping (CityModel) -> Void) {
        self.onCitySelected = onCitySelected
        let cities = (try? DataService().loadCities()) ?? []
        self.cities = cities
        self._searchViewModel = State(initialValue: CitySearchViewModel(cities: cities))
    }

    var body: some View {
        ZStack {
            MapView(
                selectedCity: self.$selectedCity,
                showAlert: self.$showAlert,
                region: self.$region,
                lastRegion: self.$lastRegion,
                cities: self.cities,
                bottomOverlayHeight: self.searchFieldHeight,
                onCitySelected: { _ in }
            )
            .ignoresSafeArea()

            // Results appear over the map in place, rather than on a new
            // screen, so the field never waits for a presentation to focus.
            if self.isSearching {
                Rectangle()
                    .fill(.background)
                    .ignoresSafeArea()
                    .transition(.opacity)

                CitySearchResultsView(viewModel: self.searchViewModel) { city in
                    self.endSearch()
                    self.navigateToCity(city)
                }
                .transition(.opacity)
            }
        }
        .safeAreaInset(edge: .bottom) {
            MapSearchField(
                text: self.$searchViewModel.query,
                isFocused: self.$isSearchFocused,
                isSearching: self.isSearching,
                onClose: self.endSearch
            )
            .padding(.horizontal, SpacingTokens.medium)
            .padding(.bottom, SpacingTokens.xSmall)
            .onGeometryChange(for: CGFloat.self, of: \.size.height) { height in
                self.searchFieldHeight = height
            }
        }
        .navigationTitle("Explore")
        // MapKit blurs the map beneath any navigation bar, so the map
        // screen goes without one and floats its search field instead.
        .toolbar(.hidden, for: .navigationBar)
        // Focusing the field starts a search; scrolling the results away
        // only lowers the keyboard, leaving the search open.
        .onChange(of: self.isSearchFocused) { _, isFocused in
            if isFocused, !self.isSearching {
                withAnimation(.smooth) {
                    self.isSearching = true
                }
            }
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

    private func endSearch() {
        self.isSearchFocused = false
        withAnimation(.smooth) {
            self.isSearching = false
            self.searchViewModel.query = ""
        }
    }

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
