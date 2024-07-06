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
    private var timer: AnyCancellable?
    
    init(cityName: String) {
        updateTime(for: cityName)
        startTimer(for: cityName)
    }
    
    private func updateTime(for cityName: String) {
        let timeZone = getTimeZone(for: cityName)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = "hh:mm:ss a"
        let timeString = dateFormatter.string(from: Date())
        let timeZoneString = timeZone.abbreviation() ?? ""
        self.currentTime = "\(timeString)\nTime Zone: \(timeZoneString)"
    }
    
    private func startTimer(for cityName: String) {
        timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect().sink { _ in
            self.updateTime(for: cityName)
        }
    }
    
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
    
    deinit {
        timer?.cancel()
    }
}
