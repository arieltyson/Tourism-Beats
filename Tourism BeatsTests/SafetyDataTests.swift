import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - SafetyDataTests

struct SafetyDataTests {
    /// The Global Peace Index ranks 163 countries each edition. Tied countries
    /// share a rank, so ranks stay within the field without being unique.
    @Test func bundledIndexCoversTheFullEdition() throws {
        let url = try #require(Bundle.main.url(forResource: "gpi_data_2026", withExtension: "json"))
        let rows = try JSONDecoder().decode([SafetyModel].self, from: Data(contentsOf: url))

        #expect(rows.count == 163)
        #expect(Set(rows.map(\.countryCode)).count == rows.count)
        #expect(rows.allSatisfy { (1 ... 163).contains($0.rank) && $0.score > 1 && $0.score < 4 })
        #expect(rows.first { $0.rank == 1 }?.countryCode == "IS")
    }
}
