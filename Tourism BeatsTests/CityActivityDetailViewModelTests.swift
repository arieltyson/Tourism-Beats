import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - CityActivityDetailViewModelTests

struct CityActivityDetailViewModelTests {
    @MainActor
    @Test func loadIfNeededEnrichesLegacyAppleMapsFallbackSummary() async {
        let activity = CityActivity(
            id: "slovak-national-gallery",
            name: "Slovak National Gallery",
            summary: "A high-demand attraction in Bratislava surfaced consistently in Apple Maps discovery results.",
            category: "Museum",
            kind: .see,
            imageURL: nil,
            officialURL: URL(string: "https://example.com/gallery"),
            sourceURL: nil,
            sourceName: "Apple Maps",
            hours: nil,
            price: nil,
            address: "Nám Ľudovíta Štúra 33/4, Bratislava",
            directions: nil,
            timingTip: nil,
            latitude: 48.1418,
            longitude: 17.1168,
            wikidataIdentifier: nil,
            sourcePageTitle: nil,
            sourceAnchor: nil
        )

        let summary = WikipediaSummary(
            title: "Slovak National Gallery",
            description: "Art museum in Bratislava",
            extract: "The Slovak National Gallery is the country's main public art museum in Bratislava.",
            thumbnailURL: URL(string: "https://example.com/thumb.jpg"),
            originalImageURL: URL(string: "https://example.com/image.jpg"),
            articleURL: URL(string: "https://en.wikipedia.org/wiki/Slovak_National_Gallery")
        )

        let viewModel = CityActivityDetailViewModel(
            activity: activity,
            cityName: "Bratislava",
            service: StubWikipediaSummaryService(summary: summary)
        )

        await viewModel.loadIfNeeded()

        #expect(viewModel.displaySummary == summary.extract)
        #expect(viewModel.enrichedDescription == summary.description)
        #expect(viewModel.displayImageURL == summary.originalImageURL)
        #expect(viewModel.articleURL == summary.articleURL)
    }
}

// MARK: - StubWikipediaSummaryService

private struct StubWikipediaSummaryService: WikipediaSummaryProviding {
    let summary: WikipediaSummary?

    func summary(for _: String, near _: String) async -> WikipediaSummary? {
        self.summary
    }
}
