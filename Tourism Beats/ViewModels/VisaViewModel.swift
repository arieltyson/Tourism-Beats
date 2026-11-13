import Observation
import SwiftUI

@MainActor
@Observable
final class VisaViewModel {
    private(set) var requirement: VisaModel?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var passportCode: String

    @ObservationIgnored private let destinationCode: String
    @ObservationIgnored private let service: VisaProtocol

    init(
        passportCode: String,
        destinationCode: String,
        service: VisaProtocol = VisaService()
    ) {
        self.passportCode = passportCode
        self.destinationCode = destinationCode
        self.service = service
    }

    /// The passport whose requirement is showing, once it has loaded.
    private var loadedPassportCode: String?

    /// Whether the chosen passport's requirement is still on its way, from
    /// before its load starts until it lands.
    var isAwaitingRequirement: Bool {
        self.errorMessage == nil && self.loadedPassportCode != self.passportCode
    }

    /// Loads the requirement for the chosen passport unless it's already
    /// showing. Coming back to the page, or showing it in another layout,
    /// reuses it; choosing another passport loads that one, and a failed load
    /// is tried again.
    func loadIfNeeded() async {
        guard self.loadedPassportCode != self.passportCode else { return }
        await self.fetchRequirement()
    }

    /// Fetches the requirement for the chosen passport. A request that's
    /// cancelled, or overtaken by another passport, publishes nothing.
    func fetchRequirement() async {
        self.isLoading = true
        self.errorMessage = nil

        let requestedPassport = self.passportCode
        do {
            let requirement = try await self.service.fetchVisaRequirement(
                passport: requestedPassport,
                destination: self.destinationCode
            )
            try Task.checkCancellation()
            guard self.passportCode == requestedPassport else { return }
            self.requirement = requirement
            self.loadedPassportCode = requestedPassport
        } catch {
            guard self.passportCode == requestedPassport else { return }
            if !Task.isCancelled {
                self.errorMessage = "Could not load visa requirements."
            }
        }

        if self.passportCode == requestedPassport {
            self.isLoading = false
        }
    }

    var summaryText: String {
        if self.passportCode.uppercased() == self.destinationCode.uppercased() {
            return "Welcome Home 🏡"
        }
        return self.requirement?.requirement ?? ""
    }

    var requirementColor: Color {
        if self.passportCode.uppercased() == self.destinationCode.uppercased() {
            return .green
        }
        guard let req = self.requirement?.requirement.lowercased() else {
            return .gray
        }
        if req.localizedStandardContains("not permitted") {
            return .red
        } else if req.localizedStandardContains("visa required") {
            return .orange
        } else if req.localizedStandardContains("visa-on-arrival") {
            return .yellow
        } else if req.localizedStandardContains("eta") || req.localizedStandardContains("e-visa") {
            return .purple
        } else if req.localizedStandardContains("visa-free") {
            return .green
        } else {
            return .gray
        }
    }
}
