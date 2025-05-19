import Foundation
import SwiftUI

@MainActor
class VisaAdvisoryViewModel: ObservableObject {
    @Published var requirement: VisaModel?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var passportCode: String
    let destinationCode: String
    private let service: VisaServiceProtocol

    init(
        passportCode: String,
        destinationCode: String,
        service: VisaServiceProtocol = VisaService()
    ) {
        self.passportCode = passportCode
        self.destinationCode = destinationCode
        self.service = service
        fetchRequirement()
    }

    func fetchRequirement() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                requirement = try await service.fetchVisaRequirement(
                    passport: passportCode,
                    destination: destinationCode
                )
            } catch {
                errorMessage = "Could not load visa requirements."
            }
            isLoading = false
        }
    }

    func updatePassport(to newCode: String) {
        passportCode = newCode
        fetchRequirement()
    }

    var summaryText: String {
        requirement?.requirement ?? ""
    }

    /// Color–code based on the text of `requirement`
    var requirementColor: Color {
        guard let req = requirement?.requirement.lowercased() else {
            return .gray
        }
        if req.contains("banned") {
            return .red
        } else if req.contains("visa required") {
            return .orange
        } else if req.contains("visa-on-arrival") {
            return .yellow
        } else if req.contains("eta") {
            return .purple
        } else if req.contains("visa-free") {
            // any visa-free (for X days or open)
            return .green
        } else {
            return .gray
        }
    }
}
