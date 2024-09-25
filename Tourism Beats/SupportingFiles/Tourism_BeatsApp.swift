//
//  Tourism_BeatsApp.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 17/6/24.
//

import SwiftUI
import TipKit

@main
struct Tourism_BeatsApp: App {
    var body: some Scene {
        WindowGroup {
            if #available(iOS 16.0, *) {
                HomePageView()
            } else {
                UnsupportedOSViewControllerWrapper()
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
    
    init() {
        if #available(iOS 17.0, *) {
            do {
                try Tips.configure([.displayFrequency(.daily)])
                print("Tips successfuly initialized !")
                //try? Tips.resetDatastore()
            } catch {
                print("Error initializing tips: \(error)")
            }
        }
    }
}
