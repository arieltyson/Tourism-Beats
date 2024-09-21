//
//  VisaService.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 20/9/24.
//

import Foundation

class VisaService: VisaServiceProtocol {
    enum VisaAPIError: Error {
        case invalidURL
        case parsingError
        case networkError(Error)
    }
    
    func checkVisaFreeTravel(fromCountryCode: String, toCountryCode: String) async throws -> Bool {
        let urlString = "https://api.visadb.io/visa-free/\(fromCountryCode.lowercased())/to/\(toCountryCode.lowercased())"
        
        guard let url = URL(string: urlString) else {
            throw VisaAPIError.invalidURL
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let visaFree = json["visa_free"] as? Bool else {
                throw VisaAPIError.parsingError
            }
            
            return visaFree
        } catch {
            throw VisaAPIError.networkError(error)
        }
    }
}
