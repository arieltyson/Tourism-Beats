//
//  VisaServiceProtocol.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 20/9/24.
//

import Foundation

protocol VisaServiceProtocol {
    func checkVisaFreeTravel(fromCountryCode: String, toCountryCode: String) async throws -> Bool
}
