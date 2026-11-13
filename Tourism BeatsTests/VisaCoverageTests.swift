import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - VisaCoverageTests

/// Visa data lists independent countries. Territories such as Martinique
/// aren't listed, as destinations or as passports, and the card says so
/// plainly instead of reporting a failure.
@MainActor
struct VisaCoverageTests {
    /// Lists requirements only for the given destinations.
    private struct StubVisaService: VisaProtocol {
        let listed: [String: String]

        func fetchVisaRequirement(passport: String, destination: String) async throws -> VisaModel {
            guard let requirement = self.listed[destination] else { throw VisaError.requirementNotFound }
            return VisaModel(passport: passport, destination: destination, requirement: requirement)
        }
    }

    @Test func anUnlistedDestinationIsNoDataRatherThanAFailure() async {
        let viewModel = VisaViewModel(
            passportCode: "CA",
            destinationCode: "MQ",
            service: StubVisaService(listed: [:])
        )

        await viewModel.loadIfNeeded()

        #expect(!viewModel.isAwaitingRequirement)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.requirement == nil)
    }

    @Test func aPassportWithNothingListedDoesNotKeepTheLastPassportsAnswer() async {
        // France is listed from Canada but not from a territory's passport.
        struct ByPassport: VisaProtocol {
            func fetchVisaRequirement(passport: String, destination: String) async throws -> VisaModel {
                guard passport == "CA" else { throw VisaError.requirementNotFound }
                return VisaModel(passport: passport, destination: destination, requirement: "Visa-free for 90 days")
            }
        }
        let viewModel = VisaViewModel(passportCode: "CA", destinationCode: "FR", service: ByPassport())
        await viewModel.loadIfNeeded()
        #expect(viewModel.requirement != nil)

        viewModel.passportCode = "PR"
        await viewModel.loadIfNeeded()

        #expect(viewModel.requirement == nil)
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isAwaitingRequirement)
    }

    @Test func onlyTerritoriesAreMissingFromTheBundledVisaData() throws {
        let visaURL = try #require(Bundle.main.url(forResource: "visa_requirements_2026", withExtension: "json"))
        let territoriesURL = try #require(Bundle.main.url(forResource: "gpi_governing_countries", withExtension: "json"))
        let listed = Set(try JSONDecoder().decode([VisaModel].self, from: Data(contentsOf: visaURL)).map(\.destination))
        let territories = Set(try JSONDecoder().decode([String: String].self, from: Data(contentsOf: territoriesURL)).keys)
        let cityCountries = Set(try DataService().loadCities().map(\.country.code))

        let unlisted = cityCountries.subtracting(listed)
        #expect(unlisted.isSubset(of: territories), "Unlisted countries that aren't territories: \(unlisted.subtracting(territories).sorted())")
    }
}
