import Foundation
import SwiftUI
import Testing
@testable import Tourism_Beats

// MARK: - VisaRequirementTests

@MainActor
struct VisaRequirementTests {
    /// Every label the view model knows how to colour. A new source value must
    /// be mapped to one of these instead of reaching the UI unstyled.
    private static let knownLabels: Set<String> = [
        "Visa required", "e-Visa", "eTA", "Visa-on-arrival", "Visa-free", "Entry not permitted"
    ]

    @Test func bundledDataCoversEveryPassportAndDestinationWithKnownLabels() throws {
        let url = try #require(Bundle.main.url(forResource: "visa_requirements_2026", withExtension: "json"))
        let rows = try JSONDecoder().decode([VisaModel].self, from: Data(contentsOf: url))
        let passports = Set(rows.map(\.passport))

        #expect(rows.count == passports.count * passports.count)
        for row in rows {
            let isKnown = Self.knownLabels.contains(row.requirement)
                || row.requirement.wholeMatch(of: /Visa-free for \d+ days/) != nil
            #expect(isKnown, "\(row.passport)->\(row.destination): \(row.requirement)")
        }
    }

    @Test(arguments: [
        ("Entry not permitted", Color.red),
        ("Visa required", .orange),
        ("Visa-on-arrival", .yellow),
        ("e-Visa", .purple),
        ("eTA", .purple),
        ("Visa-free for 90 days", .green)
    ])
    func requirementColors(requirement: String, expected: Color) async {
        let viewModel = VisaViewModel(
            passportCode: "CA",
            destinationCode: "XX",
            service: FixedVisaService(requirement: requirement)
        )

        await viewModel.fetchRequirement()

        #expect(viewModel.requirementColor == expected)
    }
}

// MARK: - FixedVisaService

private struct FixedVisaService: VisaProtocol {
    let requirement: String

    func fetchVisaRequirement(passport: String, destination: String) async throws -> VisaModel {
        VisaModel(passport: passport, destination: destination, requirement: self.requirement)
    }
}
