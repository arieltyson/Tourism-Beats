class CountryDataService: CountryDataServiceProtocol {
    private let countries: [CountryModel]

    init() {
        self.countries = CountryData.allCountries
    }

    func fetchAllCountries() -> [CountryModel] {
        return countries
    }

    func getCountryByName(_ name: String) -> CountryModel? {
        return countries.first { $0.name.lowercased() == name.lowercased() }
    }
}
