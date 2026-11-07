import Foundation
import SwiftData
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
    /// Someone who knows the city but not its country finds it by name.
    @Test func citiesAreFoundAnywhereByName() {
        let form = Self.makeForm()

        #expect(form.anyCities(matching: "").isEmpty)
        #expect(form.anyCities(matching: "nic").map(\.name) == ["Nice"])

        let nice = form.anyCities(matching: "Nice")[0]
        form.selectCity(nice)
        #expect(form.country?.name == "France")
        #expect(form.city?.name == "Nice")
        #expect(form.canAdd)
    }

    @Test func countriesNarrowBySearch() {
        let form = Self.makeForm()
        #expect(form.countries(matching: "").map(\.name) == ["France", "Japan"])
        #expect(form.countries(matching: "jap").map(\.name) == ["Japan"])
        #expect(form.countries(matching: "zzz").isEmpty)
    }

    /// Searching a city also offers its country, for a trip without one city.
    @Test func aCitySearchAlsoOffersItsCountry() {
        let form = Self.makeForm()
        #expect(form.countries(matching: "Kyo").map(\.name) == ["Japan"])
    }

    /// Countries named by the search come before those only holding a match.
    @Test func namedCountriesComeFirst() {
        let form = BucketListFormViewModel(
            countries: [Self.japan, Self.france],
            cities: [Self.city("Japan Town", in: Self.france)]
        )
        #expect(form.countries(matching: "Japan").map(\.name) == ["Japan", "France"])
    }

    /// Return ends editing instead of starting a new line.
    @Test func returnEndsEditingRatherThanBreakTheLine() {
        let form = Self.makeForm()

        #expect(!form.updateActivity("Hot air balloon"))
        #expect(form.updateActivity("Hot air balloon\n"))
        #expect(form.activity == "Hot air balloon")
    }
    /// A second tap on Add adds nothing more.
    @Test func aFormAddsItsItemOnce() throws {
        let container = try ModelContainer(
            for: BucketListItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let list = BucketListViewModel(modelContext: container.mainContext)
        let form = Self.makeForm()
        form.kind = .activity
        form.activity = "Dogsledding"

        #expect(form.add(to: list))
        #expect(!form.add(to: list))
        #expect(!form.canAdd)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<BucketListItem>()) == 1)
    }
}
