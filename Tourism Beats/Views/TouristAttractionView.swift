//
//  VideoPlayerView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 18/6/24.
//

import SwiftUI

@available(iOS 18.0, *)
struct TouristAttractionView: View {
    var city: City
    
    @State private var navigateBack = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientProvider.gradients.randomElement()?.edgesIgnoringSafeArea(.all)
                
                VStack {
                    HStack{
                        VStack(alignment: .leading) {
                            Text("\(city.name), \(city.country.name)  \(city.country.flag)" )
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .italic()
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.purple)
                                .visualEffect({ content, proxy in
                                    content
                                        .hueRotation(Angle(degrees: proxy.frame(in: .global).origin.y / 10))
                                })
                        )
                        .padding(.top, 50)
                        
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Image(city.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(15)
                            .padding(.all)
                    }
                    .padding()
                    .background(Rectangle().foregroundColor(.white))
                    .cornerRadius(15)
                    .shadow(radius: 15)
                    .padding()
                    
                    TimeWidgetView(cityName: city.name)
                        .padding(.top, 20)
                    
                    WeatherWidgetView(cityName: city.name)
                        .padding(.top, 20)
                    
                    Spacer()
                    
                    NavigationLink(value: "CitySelection") {
                        EmptyView()
                    }.hidden()
                }
                .padding()
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        navigateBack = true
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                            Text("Back")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .toolbarBackground(Color.black.opacity(0.5), for: .navigationBar)
            .onAppear {
                print("TouristAttractionView appeared for \(city.name)")
            }
            .navigationDestination(isPresented: $navigateBack) {
                CitySelectionView()
            }
        }
    }
}

@available(iOS 18.0, *)
struct TouristAttractionView_Previews: PreviewProvider {
    static var previews: some View {
        TouristAttractionView(city: CityData.cities.first!)
    }
}
