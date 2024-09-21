//
//  SafetyAdvisoryView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 20/9/24.
//

import SwiftUI

struct SafetyAdvisoryView: View {
    @ObservedObject var viewModel: SafetyAdvisoryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Travel Safety Advisory")
                .font(.headline)
            
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, 10)
            } else if let errorMessage = viewModel.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            } else if let safetyData = viewModel.safetyData {
                Text("Country: \(safetyData.name)")
                    .font(.title2)
                    .bold()
                if let advisory = safetyData.advisory {
                    Text("Risk Level: \(String(format: "%.1f", advisory.score)) / 5")
                        .font(.title3)
                    Text(advisory.message)
                        .font(.body)
                    Text("Updated: \(advisory.updated)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                } else {
                    Text("No advisory information available.")
                        .font(.body)
                }
            } else {
                Text("No safety data available.")
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.8))
        .cornerRadius(10)
        .padding()
    }
}
