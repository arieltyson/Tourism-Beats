import Observation
import SwiftUI

@MainActor
@Observable
final class CityFunFactViewModel {
    private(set) var displayedFact: CityFunFact?
    private(set) var isLoading = false

    @ObservationIgnored private let city: CityModel
    @ObservationIgnored private let service: CityFunFactProviding
    @ObservationIgnored private var facts: [CityFunFact] = []
    @ObservationIgnored private var hasLoaded = false

    init(
        city: CityModel,
        service: CityFunFactProviding = CityFunFactService.shared
    ) {
        self.city = city
        self.service = service
    }

    var canShowAnotherFact: Bool {
        self.facts.count > 1
    }

    func loadIfNeeded() async {
        guard !self.hasLoaded else { return }
        await self.load()
    }

    func showAnotherFact() {
        guard self.facts.count > 1 else { return }

        let currentText = self.displayedFact?.text
        let alternatives = self.facts.filter { $0.text != currentText }
        self.displayedFact = alternatives.randomElement() ?? self.facts.randomElement()
    }

    private func load() async {
        self.isLoading = true
        let fetchedFacts = await self.service.facts(for: self.city)
        self.facts = fetchedFacts
        self.displayedFact = fetchedFacts.randomElement()
        self.isLoading = false
        self.hasLoaded = true
    }
}
