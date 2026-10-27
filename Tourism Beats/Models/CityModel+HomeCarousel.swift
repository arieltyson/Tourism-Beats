import Foundation

extension CityModel {
    /// Hero images are curated in `cities.json` (single-scene photos only, enforced by
    /// `CityFeaturedHeroEligibilityTests`), so a city is featured unless its row opts out.
    var isEligibleForFeaturedHeroCarousel: Bool {
        self.featuredHeroEligibleOverride ?? true
    }
}
