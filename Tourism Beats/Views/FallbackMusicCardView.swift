//
//  FallbackMusicCardView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 23/9/24.
//

import SwiftUI

struct FallbackMusicCardView: View {
    var body: some View {
        VStack {
            Text("Apple Music Unavailable")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 50)

            Text("Enable Apple Music access to view top tracks for your selected city.")
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.top, 10)
                .multilineTextAlignment(.center)

            Button(action: {
                // Open settings for music access
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }) {
                Text("Open Settings")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.top, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 300)
        .background(Color.white.opacity(0.2))
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
    }
}
