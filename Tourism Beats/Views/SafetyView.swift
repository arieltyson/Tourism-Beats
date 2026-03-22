// SafetyView.swift
// Tourism Beats
//
// Displays travel safety advisory data with a risk gauge
// inside the parent AdvisoryCard's glass container.

import SwiftUI

// MARK: - SafetyView

struct SafetyView: View {
    var viewModel: SafetyViewModel

    var body: some View {
        Group {
            if self.viewModel.isLoading {
                ProgressView()
                    .controlSize(.regular)
                    .tint(.white)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else if let error = self.viewModel.errorMessage {
                SafetyErrorContent(message: error)
            } else if let safety = self.viewModel.safetyData {
                SafetyLoadedContent(
                    safety: safety,
                    riskLevelText: self.viewModel.riskLevelText,
                    riskLevelColor: self.viewModel.riskLevelColor,
                    riskScoreText: self.viewModel.riskLevelScoreText
                )
            } else {
                Text("No advisory information available.")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            await self.viewModel.fetchSafetyData()
        }
    }
}

// MARK: - SafetyLoadedContent

private struct SafetyLoadedContent: View {
    let safety: SafetyModel
    let riskLevelText: String?
    let riskLevelColor: Color?
    let riskScoreText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.small) {
            if let scoreText = self.riskScoreText,
               let levelText = self.riskLevelText,
               let color = self.riskLevelColor
            {
                SafetyRiskGauge(
                    score: self.safety.score,
                    scoreText: scoreText,
                    levelText: levelText,
                    levelColor: color
                )
            }
        }
    }
}

// MARK: - SafetyCountryLabel

private struct SafetyCountryLabel: View {
    let countryName: String

    var body: some View {
        Text(self.countryName)
            .font(TypographyTokens.cardLabel.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

// MARK: - SafetyRiskGauge

private struct SafetyRiskGauge: View {
    let score: Double
    let scoreText: String
    let levelText: String
    let levelColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
            Text("Risk Level")
                .font(TypographyTokens.footnote)
                .foregroundStyle(.secondary)

            ProgressView(value: self.score, total: 5.0)
                .tint(self.levelColor)
                .accessibilityLabel("Risk score \(self.scoreText)")

            HStack {
                Text(self.scoreText)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(self.levelText)
                    .font(TypographyTokens.cardLabel.weight(.bold))
                    .foregroundStyle(self.levelColor)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - SafetyErrorContent

private struct SafetyErrorContent: View {
    let message: String

    var body: some View {
        Label {
            Text(self.message)
                .font(TypographyTokens.caption)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        }
        .foregroundStyle(.secondary)
    }
}
