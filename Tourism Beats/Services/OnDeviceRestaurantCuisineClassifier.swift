import Foundation
import FoundationModels
import OSLog

// MARK: - OnDeviceRestaurantCuisineClassifier

/// Names restaurants' cuisines with Apple's on-device language model, which
/// knows many restaurants and reads the clues in a name, address, or website.
///
/// Answers are limited to the app's cuisine vocabulary, and the model can say
/// "Unknown", which leaves a restaurant unlabelled rather than mislabelled.
/// Nothing leaves the device. Without Apple Intelligence it labels nothing.
struct OnDeviceRestaurantCuisineClassifier: RestaurantCuisineClassifying {
    static let unknown = "Unknown"
    static let choices = RestaurantCuisineVocabulary.labels + [Self.unknown]

    private static let instructions = """
        You label restaurants with the single cuisine they are best known for.
        Use what you know about each restaurant, and clues in its name, address, and website.
        Answer Unknown unless you are reasonably confident. Never guess from the city alone.
        """

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "TourismBeats",
        category: "RestaurantCuisineClassifier"
    )

    func cuisines(
        for restaurants: [CityRestaurant],
        in city: CityModel
    ) async -> [CityRestaurant.ID: String] {
        guard !restaurants.isEmpty, case .available = SystemLanguageModel.default.availability else {
            return [:]
        }

        let session = LanguageModelSession(instructions: Self.instructions)

        do {
            let response = try await session.respond(
                to: Self.prompt(for: restaurants, in: city),
                generating: GeneratedRestaurantCuisines.self,
                options: GenerationOptions(sampling: .greedy)
            )
            return Self.labels(from: response.content, for: restaurants)
        } catch {
            Self.logger.info(
                "Cuisine labelling skipped for \(city.id, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            return [:]
        }
    }

    // MARK: - Prompt

    static func prompt(for restaurants: [CityRestaurant], in city: CityModel) -> String {
        let lines = restaurants.enumerated().map { offset, restaurant in
            let details = [restaurant.address, restaurant.websiteURL?.host()]
                .compactMap(\.self)
                .joined(separator: ", ")
            let suffix = details.isEmpty ? "" : " (\(details))"
            return "\(offset + 1). \(restaurant.name)\(suffix)"
        }

        return """
            Restaurants in \(city.name), \(city.country.name):
            \(lines.joined(separator: "\n"))
            """
    }

    /// Maps the model's numbered answers back to restaurants, dropping
    /// Unknown, out-of-range numbers, and anything outside the vocabulary.
    static func labels(
        from generated: GeneratedRestaurantCuisines,
        for restaurants: [CityRestaurant]
    ) -> [CityRestaurant.ID: String] {
        let vocabulary = Set(RestaurantCuisineVocabulary.labels)

        return generated.restaurants.reduce(into: [:]) { labels, entry in
            let index = entry.number - 1
            guard restaurants.indices.contains(index), vocabulary.contains(entry.cuisine) else { return }
            labels[restaurants[index].id] = entry.cuisine
        }
    }
}
