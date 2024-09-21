//
//  CountryModel.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 20/9/24.
//

import Foundation

struct CountryModel: Identifiable {
    let id = UUID()
    let name: String
    let code: String
    let flag: String
}
