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
        "Barcelona": "Sagrada Familia",
        "Rome": "Colosseum",
        "Beijing": "Great Wall of China",
        "Cairo": "Great Pyramid of Giza",
        "New Delhi": "India Gate",
        "Rio De Janeiro": "Christ the Redeemer",
        "Moscow": "Kremlin",
        "Amsterdam": "Van Gogh Museum",
        "Athens": "The Acropolis",
        "Bangkok": "Grand Palace"
    ]
    
    private let cityVideos = [
        "London": "big_ben1_video",
        "Paris": "eiffel_tower_video",
        "Tokyo": "tokyo_tower_video",
        "Berlin": "berlin_video",
        "Barcelona": "sagrada_familia_video",
        "Rome": "colosseum_video",
        "Beijing": "great_wall_of_china_video",
        "Cairo": "great_pyramid_of_giza_video",
        "New Delhi": "india_gate_video",
        "Rio De Janeiro": "christ_the_redeemer_video",
        "Moscow": "kremlin_video",
        "Amsterdam": "van_gogh_museum_video",
        "Athens": "the_acropolis_video",
        "Bangkok": "grand_palace_video"
    ]
    
    private let cityCountries = [
        "London": "England",
        "Paris": "France",
        "Tokyo": "Japan",
        "Berlin": "Germany",
        "Barcelona": "Spain",
        "Rome": "Italy",
        "Beijing": "China",
        "Cairo": "Egypt",
        "New Delhi": "India",
        "Rio De Janeiro": "Brazil",
        "Moscow": "Russia",
        "Amsterdam": "Netherlands",
        "Athens": "Greece",
        "Bangkok": "Thailand"
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
                    Text("Selected City: \(city), \(cityCountries[city] ?? "")")
                        .font(.headline)
                        .padding()
                        .foregroundColor(.white)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Explore \(selectedCity ?? "")?"),
                    message: Text("Would you like to explore \(selectedCity ?? ""), \(cityCountries[selectedCity ?? ""] ?? "")?"),
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
