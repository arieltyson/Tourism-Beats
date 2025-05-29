protocol CountryServiceProtocol {
    func fetchAllCountries() -> [CountryModel]
    func getCountryByName(_ name: String) -> CountryModel?
}
