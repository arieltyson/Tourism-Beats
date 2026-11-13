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

    /// Loads the requirement the first time the view appears. Coming back to
    /// the page, or showing it in another layout, reuses what's loaded. A new
    /// passport still fetches through ``updatePassport(to:)``.
    func loadIfNeeded() async {
        guard self.requirement == nil, !self.isLoading else { return }
        await self.fetchRequirement()
    }

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

    func updatePassport(to newCode: String) {
        self.passportCode = newCode
        Task {
            await self.fetchRequirement()
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
