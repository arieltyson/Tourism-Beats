// WorldView.swift
// Tourism Beats
//
// Map-based city exploration with native searchable
// interface following Apple Human Interface Guidelines.

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

    @State private var searchText = ""
    @State private var searchIndex: [SearchIndexRow] = []
    @FocusState private var isSearchFieldFocused: Bool

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
            onCitySelected: { _ in }
        )
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(
            edge: .bottom,
            spacing: SpacingTokens.small
        ) {
            WorldSearchDock(
                searchText: self.$searchText,
                results: self.filteredCities,
                isPresented: self.isSearchInterfacePresented,
                onSelect: { city in
                    self.navigateToCity(city)
                },
                onSubmit: {
                    self.handleSearchSubmit()
                },
                onClear: {
                    self.searchText = ""
                },
                searchFieldFocus: self.$isSearchFieldFocused
            )
            .padding(.horizontal, SpacingTokens.medium)
        }
        .onAppear {
            self.zoomOutOnReturn()
            self.resetState()
            self.buildSearchIndexIfNeeded()
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

    private var filteredCities: [CityModel] {
        let query = self.searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return Array(self.cities.prefix(10))
        }

        var nameMatches: [CityModel] = []
        var countryMatches: [CityModel] = []

        for row in self.searchIndex {
            if row.city.name.localizedStandardContains(query) {
                nameMatches.append(row.city)
            } else if row.city.country.name.localizedStandardContains(query) {
                countryMatches.append(row.city)
            }
        }

        return nameMatches + countryMatches
    }

    private var isSearchInterfacePresented: Bool {
        let query = self.searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return self.isSearchFieldFocused || !query.isEmpty
    }

    // MARK: - Navigation

    private func navigateToCity(_ city: CityModel) {
        self.searchText = ""
        self.isSearchFieldFocused = false
        self.lastVisitedCoordinate = city.coordinate
        self.region = MKCoordinateRegion(
            center: city.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
        )
        self.selectedCity = city
        self.onCitySelected(city)
    }

    private func handleSearchSubmit() {
        let query = self.searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, let firstResult = self.filteredCities.first else { return }
        self.navigateToCity(firstResult)
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
        self.searchText = ""
        self.isSearchFieldFocused = false
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

    // MARK: - Search Index

    private struct SearchIndexRow {
        let city: CityModel
    }

    private func buildSearchIndexIfNeeded() {
        guard self.searchIndex.isEmpty else { return }
        self.searchIndex = self.cities.map { SearchIndexRow(city: $0) }
    }
}
