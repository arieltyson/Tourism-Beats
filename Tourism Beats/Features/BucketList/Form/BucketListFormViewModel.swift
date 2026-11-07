import Foundation

// MARK: - BucketListFormViewModel

/// What's being added to the bucket list, and whether it's ready to add.
@MainActor
@Observable
final class BucketListFormViewModel {
    var kind: BucketListItemKind = .place
    var activity = ""
    private(set) var countryCode = ""
    /// The city, optional, always one in the chosen country.
    var city: CityModel?

    @ObservationIgnored private let countries: [CountryModel]
    @ObservationIgnored private let cities: [CityModel]

    init(countries: [CountryModel], cities: [CityModel]) {
        self.countries = countries
        self.cities = cities
    }

    /// A form drawing on the app's own countries and cities.
    convenience init() {
        let dataService = DataService()
        self.init(
            countries: (try? dataService.loadCountries()) ?? [],
            cities: (try? dataService.loadCities()) ?? []
        )
    }

    var country: CountryModel? {
        self.countries.first { $0.code == self.countryCode }
    }

    /// Chooses the country. A city chosen in another country is let go.
    func selectCountry(code: String) {
        self.countryCode = code
        if self.city?.country.code != code {
            self.city = nil
        }
    }

    /// Chooses a city, and with it the city's country, for someone who knows
    /// where they want to go but not which country it's in.
    func selectCity(_ city: CityModel) {
        self.countryCode = city.country.code
        self.city = city
    }

    /// The countries whose names match a search, by name.
    func countries(matching query: String) -> [CountryModel] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return self.countries
            .filter { trimmed.isEmpty || $0.name.localizedStandardContains(trimmed) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// The app's cities anywhere that match a search by name, region, or
    /// another name they go by; none until something's typed.
    func anyCities(matching query: String) -> [CityModel] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return self.cities
            .filter { city in
                city.name.localizedStandardContains(trimmed)
                    || city.alternateSearchNames.contains { $0.localizedStandardContains(trimmed) }
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// Takes in an edit to the activity. Return adds the activity rather than
    /// starting a new line, so it's true when the edit asks to add.
    func updateActivity(_ text: String) -> Bool {
        guard text.contains(where: \.isNewline) else {
            self.activity = text
            return false
        }
        self.activity = String(text.filter { !$0.isNewline })
        return true
    }

    /// The app's cities in the chosen country, by name, narrowed by a search.
    func cities(matching query: String) -> [CityModel] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return self.cities
            .filter { $0.country.code == self.countryCode }
            .filter { city in
                trimmed.isEmpty
                    || city.name.localizedStandardContains(trimmed)
                    || city.regionName.localizedStandardContains(trimmed)
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var hasCities: Bool {
        self.cities.contains { $0.country.code == self.countryCode }
    }

    var canAdd: Bool {
        switch self.kind {
        case .place: self.country != nil
        case .activity: !self.activity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    /// Adds what's been entered, if it's ready.
    @discardableResult
    func add(to list: BucketListViewModel) -> Bool {
        guard self.canAdd else { return false }
        switch self.kind {
        case .place:
            guard let country else { return false }
            list.addPlace(country: country, city: self.city)
            return true
        case .activity:
            return list.addActivity(self.activity) != nil
        }
    }
}
