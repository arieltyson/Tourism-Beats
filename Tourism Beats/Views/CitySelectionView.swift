//
//  CitySelectionView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 17/6/24.
//

import SwiftUI
import MapKit

struct CitySelectionView: View {
    @State private var selectedCity: String? = nil
    @State private var showAlert = false
    @State private var navigateToAttraction = false
    
    private let cityAttractions = [
        "London": "Big Ben",
        "Paris": "Eiffel Tower",
        "Tokyo": "Tokyo Tower",
        "Berlin": "Brandenburg Gate",
        "Madrid": "Royal Palace",
        "Rome": "Colosseum"
    ]
    
    private let cityVideos = [
        "London": "big_ben_video",
        "Paris": "eiffel_tower_video",
        "Tokyo": "tokyo_tower_video",
        "Berlin": "brandenburg_gate_video",
        "Madrid": "royal_palace_video",
        "Rome": "colosseum_video"
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Select a City")
                    .font(.largeTitle)
                    .padding()
                    .foregroundColor(.white)
                
                MapView(selectedCity: $selectedCity, showAlert: $showAlert)
                    .edgesIgnoringSafeArea(.all) // Ignore safe area
                
                if let city = selectedCity {
                    Text("Selected City: \(city)")
                        .font(.headline)
                        .padding()
                        .foregroundColor(.white)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Explore \(selectedCity ?? "")?"),
                    message: Text("Would you like to explore \(selectedCity ?? "")?"),
                    primaryButton: .default(Text("Yes"), action: {
                        // Handle the action for exploring the city
                        print("Yes tapped for \(selectedCity ?? "")")
                        navigateToAttraction = true
                    }),
                    secondaryButton: .cancel(Text("No"), action: {
                        print("No tapped for \(selectedCity ?? "")")
                        selectedCity = nil
                    })
                )
            }
            .navigationDestination(isPresented: $navigateToAttraction) {
                if let city = selectedCity, let video = cityVideos[city] {
                    TouristAttractionView(cityName: city, videoName: video)
                } else {
                    EmptyView()
                }
            }
        }
    }
}

struct CitySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        CitySelectionView()
    }
}
