import CoreLocation
import Foundation

// MARK: - CityRestaurantCandidate

struct CityRestaurantCandidate: Sendable, Hashable {
    let id: String
    let name: String
    let cuisine: String?
    let address: String?
    let hours: String?
    let phoneNumber: String?
    let websiteURL: URL?
    let sourceURL: URL?
    let sourceName: String
    let latitude: Double?
    let longitude: Double?
    let wheelchairAccessibility: CityRestaurant.AccessibilityLevel
    let offersVegetarianOptions: Bool
    let offersVeganOptions: Bool
    let hasOutdoorSeating: Bool
    let acceptsReservations: Bool
    let isNotable: Bool
    let brand: String?
}

// MARK: - CityRestaurantRanking

enum CityRestaurantRanking {
    struct ScoredCandidate: Sendable {
        let candidate: CityRestaurantCandidate
        let baseScore: Int
        let metadataCount: Int
        let topSignals: [Signal]
        let distanceFromCenter: CLLocationDistance?
        let primaryCuisineKey: String?
    }

    enum Signal: Sendable {
        case notable
        case website
        case hours
        case cuisine
        case address
        case phone
        case centralLocation
        case wheelchairAccessible
        case vegetarianOptions
        case veganOptions
        case outdoorSeating
        case reservations

        var points: Int {
            switch self {
            case .notable:
                8
            case .website:
                6
            case .hours:
                5
            case .cuisine:
                4
            case .wheelchairAccessible:
                4
            case .address:
                2
            case .phone:
                2
            case .vegetarianOptions:
                2
            case .veganOptions:
                2
            case .reservations:
                2
            case .outdoorSeating:
                1
            case .centralLocation:
                1
            }
        }

        var badgeText: String {
            switch self {
            case .notable:
                "Notable"
            case .website:
                "Website"
            case .hours:
                "Hours"
            case .cuisine:
                "Cuisine"
            case .address:
                "Address"
            case .phone:
                "Phone"
            case .centralLocation:
                "Central"
            case .wheelchairAccessible:
                "Accessible"
            case .vegetarianOptions:
                "Vegetarian"
            case .veganOptions:
                "Vegan"
            case .outdoorSeating:
                "Outdoor"
            case .reservations:
                "Reservations"
            }
        }

        var summaryFragment: String {
            switch self {
            case .notable:
                "strong local notability signals"
            case .website:
                "a direct website"
            case .hours:
                "listed opening hours"
            case .cuisine:
                "clear cuisine tags"
            case .address:
                "a mapped address"
            case .phone:
                "a direct phone number"
            case .centralLocation:
                "a convenient central location"
            case .wheelchairAccessible:
                "wheelchair accessibility details"
            case .vegetarianOptions:
                "vegetarian options"
            case .veganOptions:
                "vegan options"
            case .outdoorSeating:
                "outdoor seating"
            case .reservations:
                "reservation details"
            }
        }
    }

    static func topRestaurants(
        from candidates: [CityRestaurantCandidate],
        for city: CityModel,
        limit: Int = 6
    ) -> [CityRestaurant] {
        let scored = candidates
            .map { self.score($0, cityCoordinate: city.coordinate) }
            .sorted { lhs, rhs in
                if lhs.baseScore != rhs.baseScore {
                    return lhs.baseScore > rhs.baseScore
                }

                if lhs.metadataCount != rhs.metadataCount {
                    return lhs.metadataCount > rhs.metadataCount
                }

                return (lhs.distanceFromCenter ?? .greatestFiniteMagnitude)
                    < (rhs.distanceFromCenter ?? .greatestFiniteMagnitude)
            }

        return self.selectDiverseRestaurants(from: scored, for: city, limit: limit)
    }

    static func score(
        _ candidate: CityRestaurantCandidate,
        cityCoordinate: CLLocationCoordinate2D
    ) -> ScoredCandidate {
        var signals: [Signal] = []
        var score = 0

        if candidate.isNotable {
            signals.append(.notable)
            score += Signal.notable.points
        }

        if candidate.websiteURL != nil {
            signals.append(.website)
            score += Signal.website.points
        }

        if candidate.hours?.isEmpty == false {
            signals.append(.hours)
            score += Signal.hours.points
        }

        if candidate.cuisine?.isEmpty == false {
            signals.append(.cuisine)
            score += Signal.cuisine.points
        }

        if candidate.address?.isEmpty == false {
            signals.append(.address)
            score += Signal.address.points
        }

        if candidate.phoneNumber?.isEmpty == false {
            signals.append(.phone)
            score += Signal.phone.points
        }

        if candidate.wheelchairAccessibility == .yes {
            signals.append(.wheelchairAccessible)
            score += Signal.wheelchairAccessible.points
        } else if candidate.wheelchairAccessibility == .limited {
            score += 1
        } else if candidate.wheelchairAccessibility == .no {
            score -= 1
        }

        if candidate.offersVegetarianOptions {
            signals.append(.vegetarianOptions)
            score += Signal.vegetarianOptions.points
        }

        if candidate.offersVeganOptions {
            signals.append(.veganOptions)
            score += Signal.veganOptions.points
        }

        if candidate.hasOutdoorSeating {
            signals.append(.outdoorSeating)
            score += Signal.outdoorSeating.points
        }

        if candidate.acceptsReservations {
            signals.append(.reservations)
            score += Signal.reservations.points
        }

        let distanceFromCenter = self.distance(
            from: cityCoordinate,
            latitude: candidate.latitude,
            longitude: candidate.longitude
        )

        if let distanceFromCenter {
            if distanceFromCenter < 1_500 {
                signals.append(.centralLocation)
                score += 4
            } else if distanceFromCenter < 4_000 {
                signals.append(.centralLocation)
                score += 3
            } else if distanceFromCenter < 8_000 {
                signals.append(.centralLocation)
                score += 1
            }
        }

        if candidate.brand?.isEmpty == false {
            score -= 2
        }

        if candidate.cuisine == nil,
           candidate.hours == nil,
           candidate.websiteURL == nil
        {
            score -= 2
        }

        if self.isGenericName(candidate.name) {
            score -= 3
        }

        return ScoredCandidate(
            candidate: candidate,
            baseScore: score,
            metadataCount: self.metadataCount(for: candidate),
            topSignals: signals.sorted { lhs, rhs in
                if lhs.points != rhs.points { return lhs.points > rhs.points }
                return lhs.badgeText < rhs.badgeText
            },
            distanceFromCenter: distanceFromCenter,
            primaryCuisineKey: self.primaryCuisineKey(for: candidate.cuisine)
        )
    }

    private static func selectDiverseRestaurants(
        from scored: [ScoredCandidate],
        for city: CityModel,
        limit: Int
    ) -> [CityRestaurant] {
        var remaining = scored
        var selected: [ScoredCandidate] = []
        var seenCuisineKeys: Set<String> = []
        var representedSignals: Set<String> = []

        while selected.count < limit, !remaining.isEmpty {
            let bestIndex = remaining.indices.max { lhs, rhs in
                self.selectionScore(
                    for: remaining[lhs],
                    seenCuisineKeys: seenCuisineKeys,
                    representedSignals: representedSignals
                ) < self.selectionScore(
                    for: remaining[rhs],
                    seenCuisineKeys: seenCuisineKeys,
                    representedSignals: representedSignals
                )
            }

            guard let bestIndex else { break }
            let bestCandidate = remaining.remove(at: bestIndex)
            selected.append(bestCandidate)

            if let cuisineKey = bestCandidate.primaryCuisineKey {
                seenCuisineKeys.insert(cuisineKey)
            }

            representedSignals.formUnion(bestCandidate.topSignals.map(\.badgeText))
        }

        return selected.map { self.mapToRestaurant($0, city: city) }
    }

    private static func selectionScore(
        for candidate: ScoredCandidate,
        seenCuisineKeys: Set<String>,
        representedSignals: Set<String>
    ) -> Int {
        var adjustedScore = candidate.baseScore

        if let primaryCuisineKey = candidate.primaryCuisineKey {
            adjustedScore += seenCuisineKeys.contains(primaryCuisineKey) ? -1 : 3
        }

        let diversitySignals = ["Accessible", "Vegetarian", "Vegan", "Outdoor"]
        for signal in diversitySignals where candidate.topSignals.map(\.badgeText).contains(signal) {
            if !representedSignals.contains(signal) {
                adjustedScore += 1
            }
        }

        return adjustedScore
    }

    private static func mapToRestaurant(
        _ scoredCandidate: ScoredCandidate,
        city: CityModel
    ) -> CityRestaurant {
        let highlights = Array(scoredCandidate.topSignals.prefix(3)).map(\.badgeText)

        return CityRestaurant(
            id: scoredCandidate.candidate.id,
            name: scoredCandidate.candidate.name,
            cuisine: scoredCandidate.candidate.cuisine,
            summary: self.summary(
                for: scoredCandidate.candidate,
                city: city,
                signals: Array(scoredCandidate.topSignals.prefix(3))
            ),
            address: scoredCandidate.candidate.address,
            hours: scoredCandidate.candidate.hours,
            phoneNumber: scoredCandidate.candidate.phoneNumber,
            websiteURL: scoredCandidate.candidate.websiteURL,
            sourceURL: scoredCandidate.candidate.sourceURL,
            sourceName: scoredCandidate.candidate.sourceName,
            latitude: scoredCandidate.candidate.latitude,
            longitude: scoredCandidate.candidate.longitude,
            wheelchairAccessibility: scoredCandidate.candidate.wheelchairAccessibility,
            offersVegetarianOptions: scoredCandidate.candidate.offersVegetarianOptions,
            offersVeganOptions: scoredCandidate.candidate.offersVeganOptions,
            hasOutdoorSeating: scoredCandidate.candidate.hasOutdoorSeating,
            acceptsReservations: scoredCandidate.candidate.acceptsReservations,
            rankingScore: scoredCandidate.baseScore,
            rankingHighlights: highlights
        )
    }

    private static func summary(
        for candidate: CityRestaurantCandidate,
        city: CityModel,
        signals: [Signal]
    ) -> String {
        let cuisineLine = if let cuisine = candidate.cuisine {
            "\(candidate.name) is a mapped \(cuisine.lowercased()) restaurant in \(city.name)."
        } else {
            "\(candidate.name) is a mapped restaurant in \(city.name)."
        }

        let reasonFragments = signals.map(\.summaryFragment)
        let recommendationLine = if reasonFragments.isEmpty {
            "It stands out for the completeness of its local listing."
        } else {
            "It stands out for \(self.joinedList(reasonFragments))."
        }

        return "\(cuisineLine) \(recommendationLine)"
    }

    private static func metadataCount(for candidate: CityRestaurantCandidate) -> Int {
        [
            candidate.cuisine != nil,
            candidate.address != nil,
            candidate.hours != nil,
            candidate.phoneNumber != nil,
            candidate.websiteURL != nil,
            candidate.wheelchairAccessibility == .yes || candidate.wheelchairAccessibility == .limited,
            candidate.offersVegetarianOptions,
            candidate.offersVeganOptions,
            candidate.hasOutdoorSeating,
            candidate.acceptsReservations
        ]
        .count(where: { $0 })
    }

    private static func primaryCuisineKey(for cuisine: String?) -> String? {
        guard let cuisine else { return nil }

        let tokens = cuisine
            .components(separatedBy: "•")
            .map { token in
                token
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                    .lowercased()
            }
            .filter { !$0.isEmpty }

        return tokens.first
    }

    private static func distance(
        from coordinate: CLLocationCoordinate2D,
        latitude: Double?,
        longitude: Double?
    ) -> CLLocationDistance? {
        guard let latitude, let longitude else { return nil }

        let cityLocation = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        let restaurantLocation = CLLocation(latitude: latitude, longitude: longitude)
        return cityLocation.distance(from: restaurantLocation)
    }

    private static func isGenericName(_ name: String) -> Bool {
        let normalizedName = name
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return self.genericNames.contains(normalizedName)
    }

    private static func joinedList(_ values: [String]) -> String {
        ListFormatter.localizedString(byJoining: values)
    }

    private static let genericNames: Set<String> = [
        "restaurant",
        "restaurante",
        "restaurant & bar",
        "dining room",
        "hotel restaurant"
    ]
}
