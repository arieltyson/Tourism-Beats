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
                selectedCity: self.$selectedCity,
                showAlert: self.$showAlert,
                region: self.$region,
                lastRegion: self.$lastRegion,
                cities: self.cities
            )
            .edgesIgnoringSafeArea(.all)
        }
        .background(Color.black.ignoresSafeArea())
        .alert(isPresented: self.$showAlert) {
            Alert(
                title: Text("Explore \(self.selectedCity?.name ?? "")?"),
                message: Text(
                    "Would you like to explore \(self.selectedCity?.name ?? ""), \(self.selectedCity?.country.name ?? "")?"
                ),
                primaryButton: .default(Text("Yes")) {
                    // restore region, clear
                    self.region = self.lastRegion ?? self.region
                    self.lastRegion = nil
                    if let city = selectedCity {
                        self.onCitySelected(city)
                    }
                    self.selectedCity = nil
                },
                secondaryButton: .cancel {
                    self.region = self.lastRegion ?? self.region
                    self.lastRegion = nil
                    self.selectedCity = nil
                }
            )
        }
    }
}
