import CoreLocation
import Foundation

// MARK: - CityRestaurantWikivoyageService

/// Marks restaurants that a city's Wikivoyage guide recommends.
enum CityRestaurantWikivoyageService {
    /// Two places with the same name this far apart are different places.
    static let maximumMatchDistance: CLLocationDistance = 1_000

    /// How much of the longer name a contained name must cover, so a common
    /// word ("Cantinho") doesn't match a fuller name ("Cantinho do Avillez").
    static let minimumContainedNameCoverage = 0.5

    static func fetchEatListings(
        for city: CityModel,
        guideService: CityActivityService = .shared
    ) async -> [WikivoyageEatListing] {
        do {
            guard let pageTitle = try await guideService.wikivoyageGuidePageTitle(for: city) else {
                return []
            }

            let sections = try await guideService.wikivoyageTOCSections(for: pageTitle)
            guard let eatSection = sections.first(where: {
                $0.tocLevel == 1 && $0.line.localizedCaseInsensitiveCompare("Eat") == .orderedSame
            }) else {
                return []
            }

            // A top-level section includes its Budget, Mid-range, and Splurge parts.
            let wikitext = try await guideService.wikivoyageSectionWikitext(
                for: pageTitle,
                sectionIndex: eatSection.index
            )
            return WikivoyageEatListingParser.listings(from: wikitext)
        } catch {
            return []
        }
    }

    static func markRecommendations(
        in candidates: [CityRestaurantCandidate],
        from listings: [WikivoyageEatListing]
    ) -> [CityRestaurantCandidate] {
        guard !listings.isEmpty else { return candidates }

        return candidates.map { candidate in
            var candidate = candidate
            candidate.isGuideRecommended = listings.contains { self.listing($0, matches: candidate) }
            return candidate
        }
    }

    static func listing(_ listing: WikivoyageEatListing, matches candidate: CityRestaurantCandidate) -> Bool {
        if let listingLatitude = listing.latitude, let listingLongitude = listing.longitude,
           let candidateLatitude = candidate.latitude, let candidateLongitude = candidate.longitude
        {
            let distance = CLLocation(latitude: listingLatitude, longitude: listingLongitude)
                .distance(from: CLLocation(latitude: candidateLatitude, longitude: candidateLongitude))
            guard distance <= self.maximumMatchDistance else { return false }
        }

        let candidateName = self.normalizedName(candidate.name)
        // Guides list alternative names as "Café Piolho / Âncora d'Ouro".
        let listingNames = [listing.name, listing.alternateName]
            .compactMap(\.self)
            .flatMap { $0.components(separatedBy: " / ") }

        return listingNames.contains { self.namesMatch(self.normalizedName($0), candidateName) }
    }

    /// Equal names, or one containing the other as whole words and covering
    /// most of it, as with "Cantinho do Avillez" and "Cantinho do Avillez Porto".
    private static func namesMatch(_ lhs: String, _ rhs: String) -> Bool {
        guard !lhs.isEmpty, !rhs.isEmpty else { return false }
        if lhs == rhs { return true }

        let (shorter, longer) = lhs.count < rhs.count ? (lhs, rhs) : (rhs, lhs)
        let coverage = Double(shorter.count) / Double(longer.count)
        return coverage >= self.minimumContainedNameCoverage && " \(longer) ".contains(" \(shorter) ")
    }

    private static func normalizedName(_ name: String) -> String {
        name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .split { !$0.isLetter && !$0.isNumber }
            .joined(separator: " ")
    }
}
