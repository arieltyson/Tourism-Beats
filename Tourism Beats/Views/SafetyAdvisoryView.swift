import SwiftUI

struct SafetyAdvisoryView: View {
    @StateObject var viewModel: SafetyAdvisoryViewModel

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
                        Text("Country: \(safety.countryName)")
                            .font(.headline)
                        HStack {
                            Text(
                                "Risk Level: \(viewModel.riskLevelScoreText ?? "")"
                            )
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
