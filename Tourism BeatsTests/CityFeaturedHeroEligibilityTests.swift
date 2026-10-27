import CoreLocation
import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - CityFeaturedHeroEligibilityTests

struct CityFeaturedHeroEligibilityTests {
    @Test func citiesAreEligibleUnlessTheirRowOptsOut() {
        let defaultCity = Self.makeCity(name: "Belgrade")
        let optedOutCity = Self.makeCity(name: "Orimasvaru", featuredHeroEligibleOverride: false)

        #expect(defaultCity.isEligibleForFeaturedHeroCarousel)
        #expect(optedOutCity.isEligibleForFeaturedHeroCarousel == false)
    }

    /// Hero cards fill-crop the centre of each image, which turns a multi-photo
    /// montage or a satellite shot into an unreadable fragment. Wide panoramas
    /// crop cleanly, so they're allowed.
    @Test func catalogImagesAreSingleScenePhotos() throws {
        let compositeSignals = ["montage", "collage", "landsat"]

        for row in try Self.loadCityRows() {
            let assetName = row.imageURL.lastPathComponent.removingPercentEncoding ?? row.imageURL.lastPathComponent
            let signal = compositeSignals.first { assetName.localizedStandardContains($0) }

            #expect(signal == nil, "\(row.name)|\(row.countryCode) uses a \(signal ?? "") image: \(assetName)")
        }
    }

    /// Every city shows its own place. Only rows that are the same place under
    /// another listing may share a photo.
    @Test func citiesDoNotBorrowAnotherCitysImage() throws {
        let samePlaceGroups: Set<Set<String>> = [
            ["Jerusalem|IL", "Jerusalem|PS"],
            ["Male|MV", "Orimasvaru|MV"]
        ]

        let citiesByImage = try Dictionary(grouping: Self.loadCityRows(), by: \.imageURL)
        for (imageURL, rows) in citiesByImage where rows.count > 1 {
            let keys = Set(rows.map { "\($0.name)|\($0.countryCode)" })

            #expect(samePlaceGroups.contains(keys), "\(keys.sorted()) share \(imageURL.lastPathComponent)")
        }
    }
}

private extension CityFeaturedHeroEligibilityTests {
    struct CityRow: Decodable {
        let name: String
        let countryCode: String
        let imageURL: URL
    }

    /// Reads the catalog the app ships; unit tests run inside the app, so its bundle is `Bundle.main`.
    static func loadCityRows() throws -> [CityRow] {
        let url = try #require(Bundle.main.url(forResource: "cities.json", withExtension: nil))
        return try JSONDecoder().decode([CityRow].self, from: Data(contentsOf: url))
    }

    static func makeCity(
        name: String,
        featuredHeroEligibleOverride: Bool? = nil
    ) -> CityModel {
        CityModel(
            id: "\(name)-test",
            name: name,
            country: CountryModel(name: "Testland", code: "TT", flag: "🏳️"),
            imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/a/a0/Test.jpg")!,
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            timeZoneIdentifier: "UTC",
            featuredHeroEligibleOverride: featuredHeroEligibleOverride
        )
    }
}
