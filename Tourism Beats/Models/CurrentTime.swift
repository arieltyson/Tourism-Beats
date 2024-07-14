//
//  CurrentTime.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 13/7/24.
//

import Foundation

struct CurrentTime {
    var hours: Int
    var minutes: Int
    var seconds: Int
    var timeZone: String
    
    var formattedTime: String {
        let period = hours >= 12 ? "p.m." : "a.m."
        let formattedHours = hours % 12 == 0 ? 12 : hours % 12
        return String(format: "%02d:%02d %s", formattedHours, minutes, period, timeZone)
    }
}
