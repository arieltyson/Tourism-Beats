import CoreLocation
import Testing
@testable import Tourism_Beats

// MARK: - CityFeaturedHeroEligibilityTests

struct CityFeaturedHeroEligibilityTests {
    @Test func panoramaAndSatelliteAssetsAreExcludedFromFeaturedCarousel() {
        let panoramaCity = Self.makeCity(
            name: "Belgrade",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/Panorama_Belgrad.jpg/1280px-Panorama_Belgrad.jpg"
        )
        let satelliteCity = Self.makeCity(
            name: "Maui",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/5/5c/Maui_Landsat_Photo.jpg"
        )

        #expect(panoramaCity.isEligibleForFeaturedHeroCarousel == false)
        #expect(satelliteCity.isEligibleForFeaturedHeroCarousel == false)
    }

    @Test func explicitOverrideCanKeepCuratedHeroEligible() {
        let curatedCity = Self.makeCity(
            name: "Whistler",
            imageURL: "https://commons.wikimedia.org/wiki/Special:FilePath/Whistler%20Village%20-%20November%2018th%201pm%20-%20Mountain%20open%20%3D%20lots%20of%20happy%20faces%20%286360439503%29.jpg",
            featuredHeroEligibleOverride: true
        )

        #expect(curatedCity.isEligibleForFeaturedHeroCarousel)
    }

    @Test func knownFallbackDestinationIsExcludedFromFeaturedCarousel() {
        let fallbackCity = Self.makeCity(
            name: "Orimasvaru",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/8/83/Mal%C3%A9.jpg"
        )

        #expect(fallbackCity.isEligibleForFeaturedHeroCarousel == false)
    }
}

private extension CityFeaturedHeroEligibilityTests {
    static func makeCity(
        name: String,
        imageURL: String,
        featuredHeroEligibleOverride: Bool? = nil
    ) -> CityModel {
        CityModel(
            id: "\(name)-test",
            name: name,
            country: CountryModel(name: "Testland", code: "TT", flag: "🏳️"),
            imageURL: URL(string: imageURL)!,
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            timeZoneIdentifier: "UTC",
            featuredHeroEligibleOverride: featuredHeroEligibleOverride
        )
    }
}
