//
//  VideoPlayerView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 18/6/24.
//

import SwiftUI
import TipKit

@available(iOS 18.0, *)
struct TouristAttractionView: View {
    var city: City
    @State private var navigateBack = false
    @State private var showFutureUpdates = false
    private let highlightTip = HighlightTip()
    
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
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .fixedSize(horizontal: false, vertical: true)
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
                        .padding(.top, 40)
                        
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Image(city.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(15)
                            .padding(.all)
                        
                    }
                    .padding(1)
                    .background(Rectangle().foregroundColor(.white))
                    .cornerRadius(15)
                    .shadow(radius: 15)
                    
                    Spacer()
                    
                    HStack {
                        TimeWidgetView(cityName: city.name)
                            .frame(maxWidth: .infinity)
                        
                        WeatherWidgetView(cityName: city.name)
                            .frame(maxWidth: .infinity)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Image(systemName: "chevron.up.2")
                            .resizable()
                            .frame(width: 10, height: 10)
                            .foregroundColor(.white)
                            .padding(.bottom, 5)
                        
                        Text("Swipe up")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 50, coordinateSpace: .local)
                            .onEnded { value in if value.translation.height < 0 {
                                showFutureUpdates = true
                            }
                        }
                    )
                    
                    NavigationLink(value: "CitySelection") {
                        EmptyView()
                    }.hidden()
                }
                .padding()
                .sheet(isPresented: $showFutureUpdates) {
                    FutureUpdatesViewControllerWrapper()
                }
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
                ToolbarItem(placement: .topBarTrailing) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.white)
                            .popoverTip(highlightTip, arrowEdge: .top)
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

struct FutureUpdatesView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
            VStack {
                Text("More Good Vybes Coming Soon ...")
                    .font(.largeTitle)
                    .italic()
                    .foregroundColor(.white)
                    .padding()
            }
        }
    }
}
