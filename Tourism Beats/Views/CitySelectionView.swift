import MapKit
import SwiftUI

struct CitySelectionView: View {
    // MARK: – Selection / navigation state
    @State private var selectedCity: CityModel?
    @State private var showAlert = false
    @State private var cityToExplore: CityModel?
    @State private var navigateToAttraction = false
    @State private var navigateBack = false

    // MARK: – Map region state
    private static let initialCenter = CLLocationCoordinate2D(
        latitude: 54.5260,
        longitude: 15.2551
    )
    private static let initialSpan = MKCoordinateSpan(
        latitudeDelta: 20,
        longitudeDelta: 20
    )

    /// Current Map View
    @State private var region = MKCoordinateRegion(
        center: initialCenter,
        span: initialSpan
    )

    /// Caching “pre-zoom” region
    @State private var lastRegion: MKCoordinateRegion?

    // MARK: – Data
    private let cities: [CityModel]
    init() {
        let svc = CountryService()
        self.cities = CityData.cities(countryService: svc)
    }

    var body: some View {
        VStack {
            Text("Select a City")
                .font(.largeTitle)
                .foregroundColor(.white)
                .padding()

            MapView(
                selectedCity: $selectedCity,
                showAlert: $showAlert,
                region: $region,
                lastRegion: $lastRegion,
                cities: cities
            )
            .edgesIgnoringSafeArea(.all)
        }
        .background(Color.black.ignoresSafeArea())
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Explore \(selectedCity?.name ?? "")?"),
                message: Text(
                    "Would you like to explore \(selectedCity?.name ?? ""), \(selectedCity?.country.name ?? "")?"
                ),
                primaryButton: .default(Text("Yes")) {
                    // Restore pre-zoom
                    region = lastRegion ?? region
                    lastRegion = nil

                    // clear the selection + remember which city to push
                    let city = selectedCity!
                    selectedCity = nil
                    cityToExplore = city
                    navigateToAttraction = true
                },
                secondaryButton: .cancel(Text("No")) {
                    // Restore region and clear selection
                    region = lastRegion ?? region
                    lastRegion = nil
                    selectedCity = nil
                }
            )
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToAttraction) {
            if let city = cityToExplore {
                TouristAttractionView(city: city)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    navigateBack = true
                } label: {
                    Image(systemName: "house")
                        .foregroundColor(.white)
                }
            }
        }
        .navigationDestination(isPresented: $navigateBack) {
            HomePageView()
        }
    }
}
