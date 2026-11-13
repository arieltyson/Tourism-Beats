import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - AdvisoryLoadingTests

/// The advisories page can show its cards in more than one layout, and
/// returning to it runs each card's load again. Neither may fetch twice.
@MainActor
struct AdvisoryLoadingTests {
    @Test func safetyLoadsOnce() async {
        let service = CountingSafetyService()
        let viewModel = SafetyViewModel(city: TripPlanningFixtures.portOfSpain, safetyService: service)

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(await service.fetchCount == 1)
        #expect(viewModel.safetyData != nil)
    }

    @Test func visaLoadsOnce() async {
        let service = CountingVisaService()
        let viewModel = VisaViewModel(passportCode: "CA", destinationCode: "MA", service: service)

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(await service.fetchCount == 1)
        #expect(viewModel.requirement != nil)
    }

    @Test func visaTriesAgainAfterAFailure() async {
        let service = CountingVisaService(failuresBeforeSuccess: 1)
        let viewModel = VisaViewModel(passportCode: "CA", destinationCode: "MA", service: service)

        await viewModel.loadIfNeeded()
        #expect(viewModel.errorMessage != nil)

        await viewModel.loadIfNeeded()
        #expect(await service.fetchCount == 2)
        #expect(viewModel.requirement != nil)
    }

    @Test func visaLoadsAgainForANewPassport() async {
        let service = CountingVisaService()
        let viewModel = VisaViewModel(passportCode: "CA", destinationCode: "MA", service: service)

        await viewModel.loadIfNeeded()
        viewModel.passportCode = "FR"
        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(await service.fetchCount == 2)
    }

    @Test func pageLoadsSafetyAndWalkabilityOnceAndThenCountsAsLoaded() async {
        let safety = CountingSafetyService()
        let walkability = CountingWalkabilityService()
        let viewModel = AdvisoriesViewModel(
            city: TripPlanningFixtures.portOfSpain,
            safetyService: safety,
            visaService: CountingVisaService(),
            walkabilityService: walkability
        )
        #expect(!viewModel.hasLoaded)

        await viewModel.load()
        await viewModel.load()

        #expect(viewModel.hasLoaded)
        #expect(await safety.fetchCount == 1)
        #expect(await walkability.fetchCount == 1)
        #expect(viewModel.safety.safetyData != nil)
        #expect(viewModel.walkability.walkability != nil)
    }

    /// Before its first load the visa card waits for a requirement rather
    /// than saying there is none.
    @Test func visaAwaitsItsRequirementUntilItLoads() async {
        let viewModel = VisaViewModel(passportCode: "CA", destinationCode: "MA", service: CountingVisaService())
        #expect(viewModel.isAwaitingRequirement)

        await viewModel.loadIfNeeded()
        #expect(!viewModel.isAwaitingRequirement)

        viewModel.passportCode = "FR"
        #expect(viewModel.isAwaitingRequirement)
    }

    @Test func visaStopsAwaitingWhenItsLoadFails() async {
        let viewModel = VisaViewModel(
            passportCode: "CA",
            destinationCode: "MA",
            service: CountingVisaService(failuresBeforeSuccess: 1)
        )

        await viewModel.loadIfNeeded()

        #expect(!viewModel.isAwaitingRequirement)
        #expect(viewModel.errorMessage != nil)
    }
}

// MARK: - CountingSafetyService

private actor CountingSafetyService: SafetyProtocol {
    private(set) var fetchCount = 0

    func fetchSafetyData(for countryCode: String) async throws -> SafetyModel {
        self.fetchCount += 1
        return SafetyModel(
            countryName: "Trinidad and Tobago",
            countryCode: countryCode,
            region: "Central America and the Caribbean",
            rank: 1,
            score: 1.9,
            rankChange: 0,
            scoreChange: 0
        )
    }
}

// MARK: - CountingVisaService

private actor CountingVisaService: VisaProtocol {
    private(set) var fetchCount = 0
    private var failuresBeforeSuccess: Int

    init(failuresBeforeSuccess: Int = 0) {
        self.failuresBeforeSuccess = failuresBeforeSuccess
    }

    func fetchVisaRequirement(passport: String, destination: String) async throws -> VisaModel {
        self.fetchCount += 1
        if self.failuresBeforeSuccess > 0 {
            self.failuresBeforeSuccess -= 1
            throw URLError(.notConnectedToInternet)
        }
        return VisaModel(passport: passport, destination: destination, requirement: "Visa required")
    }
}

// MARK: - CountingWalkabilityService

private actor CountingWalkabilityService: WalkabilityProtocol {
    private(set) var fetchCount = 0

    func fetchWalkability(
        city: String,
        administrativeArea: String?,
        countryCode: String
    ) async throws -> WalkabilityModel {
        self.fetchCount += 1
        return WalkabilityModel(
            city: city,
            administrativeArea: administrativeArea,
            countryCode: countryCode,
            walkScore: 42,
            transitScore: 22
        )
    }
}
