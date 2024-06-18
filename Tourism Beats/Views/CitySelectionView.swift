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

    var body: some View {
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
        .background(Color.black.edgesIgnoringSafeArea(.all)) // Ensure background covers safe area
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Explore \(selectedCity ?? "")?"),
                message: Text("Would you like to explore \(selectedCity ?? "")?"),
                primaryButton: .default(Text("Yes"), action: {
                    // Handle the action for exploring the city
                }),
                secondaryButton: .cancel(Text("No"), action: {
                    // Handle the action for canceling
                    selectedCity = nil
                })
            )
        }
    }
}

struct CitySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        CitySelectionView()
    }
}
