import MapKit
import SwiftUI

/// A beautiful, award-winning city search overlay that follows Apple's latest design guidelines
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

    // MARK: - Computed Properties

    private var searchResults: [CityModel] {
        if searchText.isEmpty {
            return cities.prefix(10).map { $0 }
        }
        return filteredCities
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissSearch()
                }

            VStack(spacing: 0) {
                // Search header
                searchHeader

                // Search results
                searchResultsList
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
            setupInitialState()
        }
        .onChange(of: searchText) { _, newValue in
            performSearch(newValue)
        }
        .animation(
            .spring(response: 0.4, dampingFraction: 0.8),
            value: isPresented
        )
        .animation(
            .spring(response: 0.3, dampingFraction: 0.7),
            value: searchResults.count
        )
    }

    // MARK: - Search Header

    private var searchHeader: some View {
        VStack(spacing: 16) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(.secondary)
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            // Title and search field
            VStack(spacing: 16) {
                Text("Search Cities")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                searchField
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 16, weight: .medium))

            TextField("Search for a city...", text: $searchText)
                .focused($isSearchFieldFocused)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .submitLabel(.search)
                .onSubmit {
                    selectFirstResult()
                }

            if !searchText.isEmpty {
                Button(action: clearSearch) {
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

    // MARK: - Search Results List

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(searchResults, id: \.id) { city in
                    CitySearchResultRow(
                        city: city,
                        searchText: searchText
                    ) {
                        selectCity(city)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Helper Methods

    private func setupInitialState() {
        isSearchFieldFocused = true
        filteredCities = cities
    }

    private func performSearch(_ query: String) {
        isSearching = true

        if query.isEmpty {
            filteredCities = cities
        } else {
            filteredCities = cities.filter { city in
                city.name.localizedCaseInsensitiveContains(query)
                    || city.country.name.localizedCaseInsensitiveContains(query)
            }
            .sorted { city1, city2 in
                // Prioritize exact matches and name matches over country matches
                let city1NameMatch = city1.name
                    .localizedCaseInsensitiveContains(query)
                let city2NameMatch = city2.name
                    .localizedCaseInsensitiveContains(query)

                if city1NameMatch && !city2NameMatch {
                    return true
                } else if !city1NameMatch && city2NameMatch {
                    return false
                } else {
                    return city1.name < city2.name
                }
            }
        }

        isSearching = false
    }

    private func selectCity(_ city: CityModel) {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        // Animate to city location
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            region = MKCoordinateRegion(
                center: city.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
            )
        }

        // Select city (no alert for search selections)
        selectedCity = city

        // Call completion handler - this will navigate directly
        onCitySelected(city)

        // Dismiss search
        dismissSearch()
    }

    private func selectFirstResult() {
        guard let firstCity = searchResults.first else { return }
        selectCity(firstCity)
    }

    private func clearSearch() {
        searchText = ""
        isSearchFieldFocused = true
    }

    private func dismissSearch() {
        isSearchFieldFocused = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isPresented = false
        }
    }
}

// MARK: - City Search Result Row

struct CitySearchResultRow: View {
    let city: CityModel
    let searchText: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Country flag (emoji or computed from ISO code)
                cityIcon

                // City info
                VStack(alignment: .leading, spacing: 4) {
                    Text(highlightedText(city.name, searchText: searchText))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    Text(city.country.name)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                // Location icon
                Image(systemName: "location.fill")
                    .foregroundStyle(.blue)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                .quaternary.opacity(0.5),
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
        .buttonStyle(.plain)
    }

    private var cityIcon: some View {
        CountryFlagView(
            flagEmoji: city.country.flag,
            isoCode: city.country.code
        )
        .frame(width: 40, height: 30)
        .accessibilityLabel("\(city.country.name) flag")
    }

    private func highlightedText(_ text: String, searchText: String)
        -> AttributedString
    {
        var attributedString = AttributedString(text)

        if !searchText.isEmpty {
            let ranges = text.ranges(of: searchText, options: .caseInsensitive)
            for range in ranges {
                let attributedRange = Range(range, in: attributedString)!
                attributedString[attributedRange].backgroundColor = .blue
                    .opacity(0.3)
                attributedString[attributedRange].font = .system(
                    size: 16,
                    weight: .semibold
                )
            }
        }

        return attributedString
    }
}

// MARK: - Country Flag View

/// Renders a country flag inside a rounded rectangle.
/// Uses the provided `flagEmoji` when available; otherwise computes it from the ISO alpha-2 code.
private struct CountryFlagView: View {
    let flagEmoji: String
    let isoCode: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
            Text(resolvedFlag)
                .font(.system(size: 18))
                .minimumScaleFactor(0.6)
        }
    }

    private var resolvedFlag: String {
        if !flagEmoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return flagEmoji
        } else {
            return isoCode.flagEmoji
        }
    }
}

// MARK: - String Extensions

extension String {
    /// Returns all ranges of `searchString` in the receiver.
    func ranges(of searchString: String, options: String.CompareOptions = [])
        -> [Range<String.Index>]
    {
        var ranges: [Range<String.Index>] = []
        var searchStartIndex = startIndex

        while searchStartIndex < endIndex,
            let range = range(
                of: searchString,
                options: options,
                range: searchStartIndex..<endIndex
            )
        {
            ranges.append(range)
            searchStartIndex = range.upperBound
        }

        return ranges
    }

    /// Converts an ISO-3166 alpha-2 country code (e.g., "US", "CN") to the flag emoji.
    /// Returns "🏳️" if the code is invalid.
    var flagEmoji: String {
        let uppercased = uppercased()
        guard uppercased.count == 2,
            uppercased.unicodeScalars.allSatisfy({
                ("A"..."Z").contains(Character($0))
            })
        else {
            return "🏳️"
        }
        let base: UInt32 = 0x1F1E6  // Regional Indicator Symbol Letter A
        var scalars = String.UnicodeScalarView()
        for scalar in uppercased.unicodeScalars {
            if let regional = UnicodeScalar(base + (scalar.value - 65)) {
                scalars.append(regional)
            }
        }
        return String(scalars)
    }
}

// MARK: - Preview

#Preview {
    CitySearchOverlay(
        isPresented: .constant(true),
        selectedCity: .constant(nil),
        region: .constant(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: 54.5260,
                    longitude: 15.2551
                ),
                span: MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 20)
            )
        ),
        showAlert: .constant(false),
        cities: [
            CityModel(
                id: "1",
                name: "Tokyo",
                country: CountryModel(name: "Japan", code: "JP", flag: "🇯🇵"),
                imageName: "tokyo",
                coordinate: CLLocationCoordinate2D(
                    latitude: 35.6762,
                    longitude: 139.6503
                ),
                timeZoneIdentifier: "Asia/Tokyo"
            ),
            CityModel(
                id: "2",
                name: "New York",
                country: CountryModel(
                    name: "United States",
                    code: "US",
                    flag: "🇺🇸"
                ),
                imageName: "newyork",
                coordinate: CLLocationCoordinate2D(
                    latitude: 40.7128,
                    longitude: -74.0060
                ),
                timeZoneIdentifier: "America/New_York"
            ),
            CityModel(
                id: "3",
                name: "Shanghai",
                country: CountryModel(name: "China", code: "CN", flag: ""),
                imageName: "shanghai",
                coordinate: CLLocationCoordinate2D(
                    latitude: 31.2304,
                    longitude: 121.4737
                ),
                timeZoneIdentifier: "Asia/Shanghai"
            ),
        ],
        onCitySelected: { _ in }
    )
    .background(.black)
}
