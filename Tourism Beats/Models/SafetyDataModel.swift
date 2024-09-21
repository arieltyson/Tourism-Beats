//
//  SafetyDataModel.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 20/9/24.
//

import Foundation

struct SafetyDataModel: Codable, Identifiable {
    var id: String { isoAlpha2 }
    let isoAlpha2: String
    let name: String
    let continent: String
    let advisory: Advisory?
    
    enum CodingKeys: String, CodingKey {
        case isoAlpha2 = "iso_alpha2"
        case name
        case continent
        case advisory
    }
    
    struct Advisory: Codable {
        let score: Double
        let sourcesActive: Int
        let message: String
        let updated: String
        let source: String
        
        enum CodingKeys: String, CodingKey {
            case score
            case sourcesActive = "sources_active"
            case message
            case updated
            case source
        }
    }
}
