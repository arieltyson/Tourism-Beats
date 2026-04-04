// CityActivityDetailViewModel.swift
// Tourism Beats
//
// Enriches a CityActivity with additional detail from the
// Wikipedia REST API when the initial pipeline only produced
// a fallback summary or placeholder imagery.

import Foundation

@MainActor
@Observable
final class CityActivityDetailViewModel {
    private(set) var enrichedSummary: String?
    private(set) var enrichedDescription: String?
    private(set) var enrichedImageURL: URL?
    private(set) var articleURL: URL?
    private(set) var isLoading = false

    @ObservationIgnored private let activity: CityActivity
    @ObservationIgnored private let cityName: String
    @ObservationIgnored private let service: WikipediaSummaryProviding
    @ObservationIgnored private var hasLoaded = false

    init(
        activity: CityActivity,
        cityName: String,
        service: WikipediaSummaryProviding = WikipediaSummaryService.shared
    ) {
        self.activity = activity
        self.cityName = cityName
        self.service = service
    }

    /// The best available summary text, preferring the enriched Wikipedia
    /// extract over the activity's original summary.
    var displaySummary: String {
        self.enrichedSummary ?? self.activity.summary
    }

    /// The best available image URL, preferring the enriched Wikipedia
    /// image over the activity's original image.
    var displayImageURL: URL? {
        self.enrichedImageURL ?? self.activity.imageURL
    }

    /// Whether the original summary is still a generic fallback placeholder.
    var needsEnrichment: Bool {
        self.activity.hasGenericFallbackSummary
    }

    func loadIfNeeded() async {
        guard !self.hasLoaded else { return }
        self.hasLoaded = true

        guard self.needsEnrichment || self.activity.imageURL == nil else { return }

        guard let title = self.lookupTitle else { return }

        self.isLoading = true
        defer { self.isLoading = false }

        guard let wiki = await self.service.summary(for: title, near: self.cityName) else { return }

        if self.needsEnrichment, !wiki.extract.isEmpty {
            self.enrichedSummary = wiki.extract
        }

        self.enrichedDescription = wiki.description

        if self.activity.imageURL == nil {
            self.enrichedImageURL = wiki.originalImageURL ?? wiki.thumbnailURL
        }

        self.articleURL = wiki.articleURL
    }

    /// Determines the best Wikipedia title to look up.
    private var lookupTitle: String? {
        if let pageTitle = self.activity.sourcePageTitle, !pageTitle.isEmpty {
            return pageTitle
        }
        return self.activity.name
    }
}
