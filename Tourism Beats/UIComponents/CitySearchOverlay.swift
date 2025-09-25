import MapKit
import SwiftUI

struct CitySearchOverlay: View {
    @Binding var isPresented: Bool
    @Binding var selectedCity: CityModel?
    @Binding var region: MKCoordinateRegion
    @Binding var showAlert: Bool

    let cities: [CityModel]
    let onCitySelected: (CityModel) -> Void

    @State private var searchText = ""
    @State private var filteredCities: [CityModel] = []
    @State private var isSearching = false
    @FocusState private var isSearchFieldFocused: Bool

    // Lightweight preprocessed index for faster filtering
    private struct IndexRow {
        let city: CityModel
        let nameLC: String
        let countryLC: String
        let nameWords: [Substring]
    }
    @State private var index: [IndexRow] = []

    private var searchResults: [CityModel] {
        searchText.isEmpty ? Array(cities.prefix(10)) : filteredCities
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { self.dismissSearch() }

            VStack(spacing: 0) {
                self.searchHeader
                self.searchResultsList
            }
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 20)
            )
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 40)
        }
        .onAppear {
            self.setupInitialState()
            // Build a lowercased index once
            if index.isEmpty {
                self.index = self.cities.map {
                    .init(
                        city: $0,
                        nameLC: $0.name.lowercased(),
                        countryLC: $0.country.name.lowercased(),
                        nameWords: $0.name.split(separator: " ")
                    )
                }
            }
        }
        .onChange(of: self.searchText) { _, newValue in
            self.performSearch(newValue)
        }
        .animation(
            .spring(response: 0.4, dampingFraction: 0.8),
            value: self.isPresented
        )
        .animation(
            .spring(response: 0.3, dampingFraction: 0.7),
            value: self.searchResults.count
        )
    }

    // MARK: - Header

    private var searchHeader: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(.secondary)
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            VStack(spacing: 16) {
                Text("Search Cities")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                self.searchField
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Field

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 16, weight: .medium))

            TextField("Search for a city...", text: self.$searchText)
                .focused(self.$isSearchFieldFocused)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .submitLabel(.search)
                .onSubmit { self.selectFirstResult() }

            if !self.searchText.isEmpty {
                Button(action: self.clearSearch) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Results

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(self.searchResults, id: \.id) { city in
                    CitySearchResultRow(city: city, searchText: self.searchText)
                    {
                        self.selectCity(city)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Helpers

    private func setupInitialState() {
        self.isSearchFieldFocused = true
        self.filteredCities = self.cities
    }

    private func performSearch(_ query: String) {
        self.isSearching = true
        defer { self.isSearching = false }

        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !q.isEmpty else {
            self.filteredCities = self.cities
            return
        }

        // Two buckets: (1) city-name matches, (2) country-only matches.
        var nameMatches: [CityModel] = []
        var countryMatches: [CityModel] = []
        nameMatches.reserveCapacity(32)
        countryMatches.reserveCapacity(32)

        for row in index {
            if row.nameLC.contains(q)
                || row.nameWords.contains(where: {
                    $0.lowercased().hasPrefix(q)
                })
            {
                nameMatches.append(row.city)
            } else if row.countryLC.contains(q) {
                countryMatches.append(row.city)
            }
        }
        // Preserve original order; no O(n log n) sorts per keystroke.
        self.filteredCities = nameMatches + countryMatches
    }

    private func selectCity(_ city: CityModel) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            self.region = .init(
                center: city.coordinate,
                span: .init(latitudeDelta: 2, longitudeDelta: 2)
            )
        }
        self.selectedCity = city
        self.onCitySelected(city)
        self.dismissSearch()
    }

    private func selectFirstResult() {
        guard let firstCity = searchResults.first else { return }
        self.selectCity(firstCity)
    }

    private func clearSearch() {
        self.searchText = ""
        self.isSearchFieldFocused = true
    }

    private func dismissSearch() {
        self.isSearchFieldFocused = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            self.isPresented = false
        }
    }
}
