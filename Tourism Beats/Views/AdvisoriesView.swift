import SwiftUI

struct AdvisoriesView: View {
    let city: CityModel

    var body: some View {
        GeometryReader { geometry in
            // Foreground only; container paints the background
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: max(geometry.safeAreaInsets.top, 20))

                    VStack(spacing: 24) {
                        Text("Travel Advisories")
                            .font(.largeTitle.weight(.bold))
                            .italic()
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .shadow(
                                color: .black.opacity(0.3),
                                radius: 2,
                                x: 0,
                                y: 1
                            )

                        VStack(spacing: 20) {
                            SafetyView(viewModel: SafetyViewModel(city: city))
                                .fixedSize(horizontal: false, vertical: true)

                            VisaView(
                                viewModel: VisaViewModel(
                                    passportCode: "TT",
                                    destinationCode: city.country.code
                                )
                            )
                            .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(
                            .horizontal,
                            max(20, geometry.safeAreaInsets.leading + 16)
                        )
                    }

                    Spacer(
                        minLength: max(geometry.safeAreaInsets.bottom + 20, 40)
                    )
                }
                .frame(minHeight: geometry.size.height)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
