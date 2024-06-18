//
//  ContentView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 17/6/24.
//

import SwiftUI

struct HomePageView: View {
    var body: some View {
        NavigationView {
            ZStack {
                EarthSceneView()
                    .edgesIgnoringSafeArea(.all) // Make the scene view full screen
                VStack(spacing: 20) {
                    VStack {
                        Text("Tourism Beats")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .italic()
                        Text("an immersive tourist experience")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .italic()
                    }
                    .padding(.top, 50)
                    
                    Spacer()
                    
                    NavigationLink(destination: CitySelectionView()) {
                        Text("Choose a City")
                            .font(.title)
                            .padding()
                            .background(Color.black.opacity(0.5)) // Transparent background
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2) // White border for visibility
                            )
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .edgesIgnoringSafeArea(.all) // Ensure the entire ZStack ignores the safe area
            .navigationTitle("") // Empty navigation title for better appearance
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Ensures proper behavior on iPad
    }
}

struct HomePageView_Previews: PreviewProvider {
    static var previews: some View {
        HomePageView()
    }
}
