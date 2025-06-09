import MapKit
import SwiftUI

struct WorldView: View {
    let onCitySelected: (CityModel) -> Void

    // Map state
    @State private var selectedCity: CityModel?
    @State private var showAlert = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 54.5260, longitude: 15.2551),
        span: MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 20)
    )
    @State private var lastRegion: MKCoordinateRegion?

    private let cities: [CityModel]

    init(onCitySelected: @escaping (CityModel) -> Void) {
        self.onCitySelected = onCitySelected
        self.cities = (try? DataService().loadCities()) ?? []
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
                    // restore region, clear
                    region = lastRegion ?? region
                    lastRegion = nil
                    if let city = selectedCity {
                        onCitySelected(city)
                    }
                    selectedCity = nil
                },
                secondaryButton: .cancel {
                    region = lastRegion ?? region
                    lastRegion = nil
                    selectedCity = nil
                }
            )
        }
    }
}
