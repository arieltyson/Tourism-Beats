protocol CountryDataServiceProtocol {
    func fetchAllCountries() -> [CountryModel]
    func getCountryByName(_ name: String) -> CountryModel?
}
