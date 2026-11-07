import Testing
@testable import Tourism_Beats

// MARK: - WalkabilityLookupTests

/// Cities in one country that share a name each find their own scores.
struct WalkabilityLookupTests {
    @Test(arguments: [
        ("Portland", "Maine", 61),
        ("Portland", "Oregon", 68),
        ("Charleston", "South Carolina", 41),
        ("Charleston", "West Virginia", 39),
    ])
    func sharedNamesResolveByState(city: String, state: String, walkScore: Int) async throws {
        let scores = try await WalkabilityService().fetchWalkability(
            city: city,
            administrativeArea: state,
            countryCode: "US"
        )
        #expect(scores.walkScore == walkScore)
    }

    /// A city whose row names no state is still found by its name alone.
    @Test func citiesWithoutAStateInTheirRowStillResolve() async throws {
        let scores = try await WalkabilityService().fetchWalkability(
            city: "Lehi",
            administrativeArea: "Utah",
            countryCode: "US"
        )
        #expect(scores.city == "Lehi")
    }
}
