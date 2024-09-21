//
//  SafetyAdvisoryViewModel.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 20/9/24.
//

import Foundation
import SwiftUICore

@MainActor
class SafetyAdvisoryViewModel: ObservableObject {
    @Published var safetyData: SafetyDataModel?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    let city: CityModel
    private let safetyService: SafetyServiceProtocol

    init(city: CityModel, safetyService: SafetyServiceProtocol = SafetyService()) {
        self.city = city
        self.safetyService = safetyService
        fetchSafetyData()
    }

    func fetchSafetyData() {
        isLoading = true
        errorMessage = nil

        let countryCode = city.country.code
        print("Fetching safety data for country code: \(countryCode)")

        Task {
            do {
                let data = try await safetyService.fetchSafetyData(for: countryCode)
                self.safetyData = data
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }
    
    var riskLevelText: String? {
        guard let score = safetyData?.advisory?.score else { return nil }
        switch score {
        case ..<2.5:
            return "LOW"
        case 2.5..<3.5:
            return "MED"
        case 3.5...:
            return "HIGH"
        default:
            return "Unknown"
        }
    }
    
    var riskLevelColor: Color? {
        guard let score = safetyData?.advisory?.score else { return nil }
        switch score {
        case ..<2.5:
            return .green
        case 2.5..<3.5:
            return .yellow
        case 3.5...:
            return .red
        default:
            return .gray
        }
    }
        
    var riskLevelScoreText: String? {
        guard let score = safetyData?.advisory?.score else { return nil }
        let roundedScore = Int(score)
        return "\(roundedScore) / 5"
    }
    
    var advisoryUpdatedText: String? {
        guard let updated = safetyData?.advisory?.updated else { return nil }
        return "Updated: \(updated)"
    }
}
