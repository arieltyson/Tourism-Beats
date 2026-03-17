import Foundation
import Testing
@testable import Tourism_Beats

@MainActor
struct FeedbackMailComposerTests {
    @Test func bugFeedbackURLIncludesExpectedSubjectAndContext() throws {
        let composer = FeedbackMailComposer(
            category: .bug,
            message: "Map pin is offset after zooming."
        )

        let mailURL = try #require(composer.mailURL)
        let components = try #require(
            URLComponents(url: mailURL, resolvingAgainstBaseURL: false)
        )
        let queryItems = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map {
                ($0.name, $0.value ?? "")
            }
        )

        #expect(components.scheme == "mailto")
        #expect(components.path == FeedbackMailComposer.supportEmail)
        #expect(queryItems["subject"] == FeedbackCategory.bug.emailSubject)
        #expect(queryItems["body"]?.contains("Map pin is offset after zooming.") == true)
        #expect(queryItems["body"]?.contains("App Version:") == true)
        #expect(queryItems["body"]?.contains("Device:") == true)
        #expect(queryItems["body"]?.contains("System:") == true)
    }
}
