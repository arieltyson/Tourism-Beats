import Foundation

extension CityModel {
    var isEligibleForFeaturedHeroCarousel: Bool {
        self.featuredHeroEligibleOverride
            ?? !self.hasPotentiallyRiskyFeaturedHeroAsset
    }

    private var hasPotentiallyRiskyFeaturedHeroAsset: Bool {
        if self.name == "Orimasvaru" {
            return true
        }

        let decodedAssetName =
            self.imageURL.lastPathComponent.removingPercentEncoding
            ?? self.imageURL.absoluteString.removingPercentEncoding
            ?? self.imageURL.absoluteString

        let riskSignals = [
            "panorama",
            "panoramic",
            "montage",
            "collage",
            "landsat"
        ]

        return riskSignals.contains { decodedAssetName.localizedStandardContains($0) }
    }
}
