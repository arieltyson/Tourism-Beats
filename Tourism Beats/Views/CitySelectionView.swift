//
//  CitySelectionView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 17/6/24.
//

import SwiftUI
import MapKit

struct CitySelectionView: View {
    @State private var selectedCity: CityModel? = nil
    @State private var showAlert = false
    @State private var navigateToAttraction = false
    @State private var navigateBack = false
    
    let countryDataService = CountryDataService()
    var cities: [CityModel] {
        CityData.cities(countryDataService: countryDataService)
    }
    
    var body: some View {
        VStack {
            Text("Select a City")
                .font(.largeTitle)
                .padding()
                .foregroundColor(.white)
            
            MapView(selectedCity: $selectedCity, showAlert: $showAlert, cities: cities)
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
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToAttraction) {
            if let city = selectedCity {
                TouristAttractionView(city: city)
            } else {
                EmptyView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    navigateBack = true
                }) {
                    HStack {
                        Image(systemName: "house")
                            .foregroundColor(.white)
                        Text("")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .navigationDestination(isPresented: $navigateBack) {
            HomePageView()
        }
    }
}

@available(iOS 18.0, *)
struct CitySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        CitySelectionView()
    }
}
