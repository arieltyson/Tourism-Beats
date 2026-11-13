import Observation

// MARK: - AdvisoriesViewModel

/// The advisories page's cards, loaded together by the page.
///
/// The page loads once, as soon as it's built, which is before it comes on
/// screen. Every layout the page tries shares these models, so trying one
/// never loads anything again. The visa card loads separately, whenever its
/// passport changes.
@MainActor
@Observable
final class AdvisoriesViewModel {
    let safety: SafetyViewModel
    let visa: VisaViewModel
    let walkability: WalkabilityViewModel

    /// Whether the safety and walkability cards have finished loading, with
    /// their data or an error.
    private(set) var hasLoaded = false

    init(
        city: CityModel,
        passportCode: String = AdvisoriesViewModel.defaultPassportCode,
        safetyService: SafetyProtocol = SafetyService(),
        visaService: VisaProtocol = VisaService(),
        walkabilityService: WalkabilityProtocol = WalkabilityService()
    ) {
        self.safety = SafetyViewModel(city: city, safetyService: safetyService)
        self.visa = VisaViewModel(
            passportCode: passportCode,
            destinationCode: city.country.code,
            service: visaService
        )
        self.walkability = WalkabilityViewModel(city: city, service: walkabilityService)
    }

    /// The passport the visa card starts with.
    nonisolated static let defaultPassportCode = "TT"

    /// Loads the safety and walkability cards side by side.
    func load() async {
        async let safety: Void = self.safety.loadIfNeeded()
        async let walkability: Void = self.walkability.load()
        _ = await (safety, walkability)
        self.hasLoaded = true
    }
}
