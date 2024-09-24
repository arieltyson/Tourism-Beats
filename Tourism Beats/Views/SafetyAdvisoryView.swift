//
//  SafetyAdvisoryView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 20/9/24.
//

import SwiftUI

struct SafetyAdvisoryView: View {
    @StateObject var viewModel: SafetyAdvisoryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Travel Safety Advisory")
                .font(.largeTitle)
                .italic()
                .foregroundColor(.blue)
            
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
                
                if let riskLevelScoreText = viewModel.riskLevelScoreText {
                    Text("Risk Level: \(riskLevelScoreText)")
                        .font(.title3)
                }
                    
                if let riskLevelText = viewModel.riskLevelText, let riskLevelColor = viewModel.riskLevelColor {
                    Text(riskLevelText)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(riskLevelColor)
                }
                    
                if let advisoryUpdatedText = viewModel.advisoryUpdatedText {
                    Text(advisoryUpdatedText)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            } else {
                Text("No advisory information available.")
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.8))
        .cornerRadius(10)
        .padding()
    }
}
