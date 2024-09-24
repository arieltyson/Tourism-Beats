//
//  TimeViewModel.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 6/7/24.
//

import Foundation
import Combine

class TimeViewModel: ObservableObject {
    @Published var currentTime: String = ""
    @Published var currentHour: Int = 0
    @Published var currentMinute: Int = 0
    @Published var currentSecond: Int = 0
    private var timer: AnyCancellable?
    
    private let cityTimeZones: [String: String] = [
        "London": "Europe/London",
        "Paris": "Europe/Paris",
        "Tokyo": "Asia/Tokyo",
        "Berlin": "Europe/Berlin",
        "Madrid": "Europe/Madrid",
        "Barcelona": "Europe/Madrid",
        "Rome": "Europe/Rome",
        "Beijing": "Asia/Shanghai",
        "Cairo": "Africa/Cairo",
        "New Delhi": "Asia/Kolkata",
        "Rio De Janeiro": "America/Sao_Paulo",
        "Moscow": "Europe/Moscow",
        "Amsterdam": "Europe/Amsterdam",
        "Athens": "Europe/Athens",
        "Bangkok": "Asia/Bangkok",
        "Lagos": "Africa/Lagos",
        "Cape Town": "Africa/Johannesburg",
        "Nairobi": "Africa/Nairobi",
        "Stockholm": "Europe/Stockholm",
        "Istanbul": "Europe/Istanbul",
        "Copenhagen": "Europe/Copenhagen",
        "Dubai": "Asia/Dubai",
        "Tehran": "Asia/Tehran",
        "Shanghai": "Asia/Shanghai",
        "Sydney": "Australia/Sydney",
        "Melbourne": "Australia/Melbourne",
        "Buenos Aires": "America/Argentina/Buenos_Aires",
        "Santiago": "America/Santiago",
        "Lima": "America/Lima",
        "Bogota": "America/Bogota",
        "Caracas": "America/Caracas",
        "Port of Spain": "America/Port_of_Spain",
        "Kingston": "America/Jamaica",
        "Mexico City": "America/Mexico_City",
        "Los Angeles": "America/Los_Angeles",
        "San Francisco": "America/Los_Angeles",
        "Vancouver": "America/Vancouver",
        "Houston": "America/Chicago",
        "Dallas": "America/Chicago",
        "Chicago": "America/Chicago",
        "Washington": "America/New_York",
        "New York": "America/New_York",
        "Toronto": "America/Toronto",
        "Montreal": "America/Toronto",
        "Hong Kong": "Asia/Hong_Kong",
        "Seoul": "Asia/Seoul",
        "Mumbai": "Asia/Kolkata"
    ]
    
    init(cityName: String) {
        updateTime(for: cityName)
        startTimer(for: cityName)
    }
    
    private func updateTime(for cityName: String) {
        let timeZone = getTimeZone(for: cityName)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = "hh:mm a"
        let timeString = dateFormatter.string(from: Date())
        let gmtOffset = timeZone.secondsFromGMT() / 3600
        let gmtOffsetString = gmtOffset >= 0 ? "GMT +\(gmtOffset)" : "GMT \(gmtOffset)"
        self.currentTime = "\(timeString) (\(gmtOffsetString))"
        
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: timeZone, from: Date())
        currentHour = components.hour ?? 0
        currentMinute = components.minute ?? 0
        currentSecond = components.second ?? 0
    }
    
    private func startTimer(for cityName: String) {
        timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect().sink { _ in
            self.updateTime(for: cityName)
        }
    }
    
    private func getTimeZone(for cityName: String) -> TimeZone {
        if let identifier = cityTimeZones[cityName], let timeZone = TimeZone(identifier: identifier) {
            return timeZone
        } else {
            print("Warning: Time zone not found for city '\(cityName)'. Using current time zone.")
            return TimeZone.current
        }
    }
    
    deinit {
        timer?.cancel()
    }
}
