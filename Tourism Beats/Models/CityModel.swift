//
//  CityModel.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 12/7/24.
//

import Foundation

struct City {
    let name: String
    let country: Country
    let imageName: String
}

struct Country {
    let name: String
    let flag: String
}

struct CityData {
    static let cities: [City] = [
        City(name: "London", country: Country(name: "England", flag: "🏴󠁧󠁢󠁥󠁮󠁧󠁿"), imageName: "big_ben_image"),
        City(name: "Paris", country: Country(name: "France", flag: "🇫🇷"), imageName: "eiffel_tower_image"),
        City(name: "Tokyo", country: Country(name: "Japan", flag: "🇯🇵"), imageName: "tokyo_tower_image"),
        City(name: "Berlin", country: Country(name: "Germany", flag: "🇩🇪"), imageName: "brandenburg_gate_image"),
        City(name: "Barcelona", country: Country(name: "Spain", flag: "🇪🇸"), imageName: "sagrada_familia_image"),
        City(name: "Rome", country: Country(name: "Italy", flag: "🇮🇹"), imageName: "colosseum_image"),
        City(name: "Beijing", country: Country(name: "China", flag: "🇨🇳"), imageName: "great_wall_of_china_image"),
        City(name: "Cairo", country: Country(name: "Egypt", flag: "🇪🇬"), imageName: "great_pyramid_of_giza_image"),
        City(name: "New Delhi", country: Country(name: "India", flag: "🇮🇳"), imageName: "india_gate_image"),
        City(name: "Rio De Janeiro", country: Country(name: "Brazil", flag: "🇧🇷"), imageName: "christ_the_redeemer_image"),
        City(name: "Moscow", country: Country(name: "Russia", flag: "🇷🇺"), imageName: "kremlin_image"),
        City(name: "Amsterdam", country: Country(name: "Netherlands", flag: "🇳🇱"), imageName: "van_gogh_museum_image"),
        City(name: "Athens", country: Country(name: "Greece", flag: "🇬🇷"), imageName: "the_acropolis_image"),
        City(name: "Bangkok", country: Country(name: "Thailand", flag: "🇹🇭"), imageName: "grand_palace_image")
    ]
}
