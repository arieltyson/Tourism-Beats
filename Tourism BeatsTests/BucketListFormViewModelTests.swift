import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - BucketListFormViewModelTests

@MainActor
struct BucketListFormViewModelTests {
    private static let japan = CountryModel(name: "Japan", code: "JP", flag: "🇯🇵")
    private static let france = CountryModel(name: "France", code: "FR", flag: "🇫🇷")

    private static func city(_ name: String, in country: CountryModel) -> CityModel {
        CityModel(
            id: "\(name)-\(country.code)",
            name: name,
            country: country,
            imageURL: URL(filePath: "/\(name).jpg"),
            coordinate: .init(latitude: 0, longitude: 0),
            timeZoneIdentifier: "UTC"
        )
    }

    private static func makeForm() -> BucketListFormViewModel {
        BucketListFormViewModel(
            countries: [japan, france],
            cities: [city("Osaka", in: japan), city("Kyoto", in: japan), city("Nice", in: france)]
        )
    }

    @Test func aPlaceNeedsOnlyACountry() {
        let form = Self.makeForm()
        #expect(!form.canAdd)

        form.selectCountry(code: "JP")
        #expect(form.canAdd)
        #expect(form.city == nil)
    }

    @Test func anActivityNeedsWords() {
        let form = Self.makeForm()
        form.kind = .activity

        form.activity = "   "
        #expect(!form.canAdd)

        form.activity = "Dogsledding"
        #expect(form.canAdd)
    }

    @Test func citiesAreTheCountrysOwnInOrder() {
        let form = Self.makeForm()
        form.selectCountry(code: "JP")

        #expect(form.cities(matching: "").map(\.name) == ["Kyoto", "Osaka"])
        #expect(form.cities(matching: "osa").map(\.name) == ["Osaka"])
    }

    /// Changing country lets go of a city in the old one.
    @Test func changingCountryClearsTheCity() {
        let form = Self.makeForm()
        form.selectCountry(code: "JP")
        form.city = form.cities(matching: "Kyoto").first

        form.selectCountry(code: "JP")
        #expect(form.city?.name == "Kyoto")

        form.selectCountry(code: "FR")
        #expect(form.city == nil)
    }
}
