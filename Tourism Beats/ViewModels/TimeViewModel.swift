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
        case "Beijing":
            return TimeZone(identifier: "Asia/Shanghai")!
        case "Cairo":
            return TimeZone(identifier: "Africa/Cairo")!
        case "New Delhi":
            return TimeZone(identifier: "Asia/Kolkata")!
        case "Rio De Janeiro":
            return TimeZone(identifier: "America/Sao_Paulo")!
        case "Moscow":
            return TimeZone(identifier: "Europe/Moscow")!
        case "Amsterdam":
            return TimeZone(identifier: "Europe/Amsterdam")!
        case "Athens":
            return TimeZone(identifier: "Europe/Athens")!
        case "Bangkok":
            return TimeZone(identifier: "Asia/Bangkok")!
        default:
            return TimeZone.current
        }
    }
    
    deinit {
        timer?.cancel()
    }
}
