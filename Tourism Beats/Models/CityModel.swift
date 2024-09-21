//
//  CityModel.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 12/7/24.
//

import Foundation

struct CityModel: Identifiable {
    let id = UUID()
    let name: String
    let country: CountryModel
    let imageName: String
}
