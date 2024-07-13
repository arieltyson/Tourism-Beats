//
//  CitySelectionView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 17/6/24.
//

import SwiftUI
import MapKit

@available(iOS 18.0, *)
struct CitySelectionView: View {
    @State private var selectedCity: City? = nil
    @State private var showAlert = false
    @State private var navigateToAttraction = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Select a City")
                    .font(.largeTitle)
                    .padding()
                    .foregroundColor(.white)
                
                MapView(selectedCity: $selectedCity, showAlert: $showAlert)
                    .edgesIgnoringSafeArea(.all)
                
                if let city = selectedCity {
                    Text("Selected City: \(city.name), \(city.country.name)")
                        .font(.headline)
                        .padding()
                        .foregroundColor(.white)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Explore \(selectedCity?.name ?? "")?"),
                    message: Text("Would you like to explore \(selectedCity?.name ?? ""), \(selectedCity?.country.name ?? "")?"),
                    primaryButton: .default(Text("Yes"), action: {
                        print("Yes tapped for \(selectedCity?.name ?? "")")
                        navigateToAttraction = true
                    }),
                    secondaryButton: .cancel(Text("No"), action: {
                        print("No tapped for \(selectedCity?.country.name ?? "")")
                        selectedCity = nil
                    })
                )
            }
            .navigationDestination(isPresented: $navigateToAttraction) {
                if let city = selectedCity {
                    TouristAttractionView(city: city)
                } else {
                    EmptyView()
                }
            }
        }
    }
}

@available(iOS 18.0, *)
struct CitySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        CitySelectionView()
    }
}
