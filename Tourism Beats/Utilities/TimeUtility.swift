//
//  TimeUtility.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 13/7/24.
//

import Foundation

struct TimeUtility {
    private func getTimeZone(for cityName: String) -> TimeZone {
        switch cityName {
        case "London":
            return TimeZone(identifier: "Europe/London")!
        case "Paris":
            return TimeZone(identifier: "Europe/Paris")!
        case "Tokyo":
            return TimeZone(identifier: "Asia/Tokyo")!
        case "Berlin":
            return TimeZone(identifier: "Europe/Berlin")!
        case "Madrid":
            return TimeZone(identifier: "Europe/Madrid")!
        case "Rome":
            return TimeZone(identifier: "Europe/Rome")!
        default:
            return TimeZone.current
        }
    }
}
