//
//  SafetyService.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 20/9/24.
//

import Foundation

class SafetyService: SafetyServiceProtocol {
    func fetchSafetyData(for countryCode: String) async throws -> SafetyDataModel {
        let urlString = "https://www.travel-advisory.info/api?countrycode=\(countryCode.uppercased())"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(TravelAdvisoryAPIResponse.self, from: data)

        guard let safetyData = apiResponse.data[countryCode.uppercased()] else {
            throw DataError.dataUnavailable
        }

        return safetyData
    }

    enum DataError: Error {
        case dataUnavailable
    }
}
