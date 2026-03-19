import Foundation
import Testing
@testable import Tourism_Beats

struct TourismBeatsAppStoreTests {
    @Test func reviewURLTargetsThePublishedWriteReviewPage() throws {
        let components = try #require(
            URLComponents(
                url: TourismBeatsAppStore.reviewURL,
                resolvingAgainstBaseURL: false
            )
        )
        let queryItems = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map {
                ($0.name, $0.value ?? "")
            }
        )

        #expect(components.scheme == "https")
        #expect(components.host == "apps.apple.com")
        #expect(components.path == "/app/id\(TourismBeatsAppStore.appID)")
        #expect(queryItems["action"] == "write-review")
    }
}
