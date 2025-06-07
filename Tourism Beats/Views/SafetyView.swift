import SwiftUI

struct SafetyView: View {
    @StateObject var viewModel: SafetyViewModel

    var body: some View {
        NeumorphicCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Travel Safety Advisory")
                    .font(.title2.italic())
                    .foregroundColor(.blue)

                Group {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if let err = viewModel.errorMessage {
                        Text("Error: \(err)")
                            .foregroundColor(.red)
                    } else if let safety = viewModel.safetyData {
                        HStack {
                            Text("Country: ")
                                .foregroundColor(.primary)
                            Text("\(safety.countryName)")
                                .foregroundColor(.indigo)
                        }
                        .font(.headline)
                        HStack {
                            Text(
                                "Risk Level: "
                            )
                            .foregroundColor(.primary)
                            .bold()

                            Text(
                                "\(viewModel.riskLevelScoreText ?? "")"
                            )
                            .foregroundColor(.mint)
                            .bold()

                            Spacer()

                            Text(viewModel.riskLevelText ?? "")
                                .fontWeight(.bold)
                                .foregroundColor(viewModel.riskLevelColor)
                        }
                    } else {
                        Text("No advisory information available.")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.primary)
            }
        }
        .padding()
    }
}
