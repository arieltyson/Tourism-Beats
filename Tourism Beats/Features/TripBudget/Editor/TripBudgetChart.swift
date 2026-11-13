import Charts
import SwiftUI

// MARK: - TripBudgetChart

/// The budget as a ring of its categories around its total.
struct TripBudgetChart: View {
    let budget: TripBudget
    let length: TripLength

    @ScaledMetric(relativeTo: .largeTitle) private var height = TripBudgetTokens.chartHeight

    var body: some View {
        Chart(TripBudgetCategory.allCases) { category in
            SectorMark(
                angle: .value("Amount", self.budget.amount(for: category)),
                innerRadius: .ratio(TripBudgetTokens.chartInnerRadiusRatio),
                angularInset: TripBudgetTokens.sectorInset
            )
            .cornerRadius(TripBudgetTokens.sectorCornerRadius)
            .foregroundStyle(category.color)
        }
        .chartLegend(.hidden)
        .frame(height: self.height)
        .overlay {
            VStack(spacing: SpacingTokens.xxSmall) {
                Text(self.budget.total, format: .budget(self.budget.currencyCode))
                    .font(.title.bold())
                    .monospacedDigit()
                    .contentTransition(.numericText(value: self.budget.total))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text(self.length.days == 1 ? "for 1 day" : "for \(self.length.days.formatted()) days")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, SpacingTokens.xLarge)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Budget")
        .accessibilityValue(self.accessibilitySummary)
    }

    private var accessibilitySummary: String {
        let format: FloatingPointFormatStyle<Double>.Currency = .budget(self.budget.currencyCode)
        let parts = TripBudgetCategory.allCases.map { category in
            "\(category.label) \(self.budget.amount(for: category).formatted(format))"
        }
        return "\(self.budget.total.formatted(format)): \(parts.formatted(.list(type: .and)))"
    }
}
