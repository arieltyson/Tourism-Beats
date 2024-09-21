//
//  SafetyServiceProtocol.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 20/9/24.
//

import Foundation

protocol SafetyServiceProtocol {
    func fetchSafetyData(for countryCode: String) async throws -> SafetyDataModel
}

