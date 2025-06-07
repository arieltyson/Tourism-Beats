import SwiftUI
import TipKit
import UIKit

struct TouristAttractionView: View {
    let city: CityModel

    // Use SwiftUI's dismiss to pop back to the map
    @Environment(\.dismiss) private var dismiss

    @State private var showMusicRecommendations = false

    var body: some View {
        ZStack {
            if #available(iOS 18.0, *) {
                GradientProvider.gradients.randomElement()?
                    .edgesIgnoringSafeArea(.all)
            } else {
                UIKitGradientBackgroundWrapper()
                    .edgesIgnoringSafeArea(.all)
            }

            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text(
                            "\(city.name), \(city.country.name)  \(city.country.flag)"
                        )
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .italic()
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                }
                .padding(.horizontal)

                Spacer()

                // Attraction image
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

                // Time & Weather widgets
                HStack {
                    TimeWidgetView(cityName: city.name)
                        .frame(maxWidth: .infinity)

                    WeatherWidgetView(city: city)
                        .frame(maxWidth: .infinity)
                }

                Spacer()

                // Swipe hint
                VStack {
                    Image(systemName: "chevron.left.2")
                        .resizable()
                        .frame(width: 10, height: 10)
                        .foregroundColor(.white)
                        .padding(.bottom, 5)

                    Text("Swipe left")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            .padding()
            // Navigate to Music recommendations on left swipe
            .navigationDestination(isPresented: $showMusicRecommendations) {
                MusicRecommendationView(
                    city: city,
                    fallbackView: FallbackMusicCardView()
                )
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.width < -50 {
                        showMusicRecommendations = true
                    } else if value.translation.width > 50 {
                        // Pop back to the map view
                        dismiss()
                    }
                }
        )
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Custom back button to dismiss
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                        Text("🌎")
                            .foregroundColor(.white)
                    }
                }
            }
            // Info tip if available
            if #available(iOS 18.0, *) {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.white)
                        .popoverTip(HighlightTip(), arrowEdge: .top)
                }
            }
        }
        .toolbarBackground(Color.black.opacity(0.5), for: .navigationBar)
    }
}
