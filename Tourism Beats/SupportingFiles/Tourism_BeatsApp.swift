//
//  Tourism_BeatsApp.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 17/6/24.
//

import SwiftUI
import TipKit

@available(iOS 18.0, *)
@main
struct Tourism_BeatsApp: App {
    var body: some Scene {
        WindowGroup {
            HomePageView()
        }
    }
    
    init() {
        do {
            try Tips.configure()
            print("Tips successfuly initialized !")
            try? Tips.resetDatastore()
        } catch {
            print("Error initializing tips: \(error)")
        }
    }
}
