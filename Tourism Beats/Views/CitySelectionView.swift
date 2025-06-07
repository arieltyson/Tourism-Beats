import MapKit
import SwiftUI

struct CitySelectionView: View {
    // MARK: - State Properties
    @State private var selectedCity: CityModel? = nil
    @State private var showAlert = false
    @State private var navigateToAttraction = false
    @State private var navigateBack = false

    // MARK: - Data Properties
    let cities: [CityModel]

    init() {
        let countryService = CountryService()
        self.cities = CityData.cities(countryDataService: countryService)
    }

    // MARK: - Body
    var body: some View {
        VStack {
            Text("Select a City")
                .font(.largeTitle)
                .padding()
                .foregroundColor(.white)

            MapView(
                selectedCity: $selectedCity,
                showAlert: $showAlert,
                cities: cities
            )
            .edgesIgnoringSafeArea(.all)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Explore \(selectedCity?.name ?? "")?"),
                message: Text(
                    "Would you like to explore \(selectedCity?.name ?? ""), \(selectedCity?.country.name ?? "")?"
                ),
                primaryButton: .default(
                    Text("Yes"),
                    action: {
                        navigateToAttraction = true
                    }
                ),
                secondaryButton: .cancel(
                    Text("No"),
                    action: {
                        selectedCity = nil
                    }
                )
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

@available(iOS 18.0, *)
struct CitySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        CitySelectionView()
    }
}
