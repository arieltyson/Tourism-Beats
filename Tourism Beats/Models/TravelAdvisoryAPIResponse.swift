//
//  TravelAdvisoryAPIResponse.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 20/9/24.
//


import Foundation

struct TravelAdvisoryAPIResponse: Codable {
    let data: [String: SafetyDataModel]
    let apiStatus: APIStatus?

    enum CodingKeys: String, CodingKey {
        case data
        case apiStatus = "api_status"
    }
}

struct APIStatus: Codable {
    let request: Request
    let reply: Reply

    struct Request: Codable {
        let item: String
    }

    struct Reply: Codable {
        let cache: String
        let code: Int
        let status: String
        let note: String
        let count: Int
    }
}
