import SwiftUI

struct TimeView: View {
    @StateObject private var viewModel: TimeViewModel

    init(city: CityModel) {
        _viewModel = StateObject(
            wrappedValue: TimeViewModel(timeZone: city.timeZone)
        )
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 8) {
                // -- Analog clock --
                ClockView(
                    date: context.date,
                    timeZone: self.viewModel.timeZone
                )
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 120, maxHeight: 120)
                .padding(.horizontal, 12)
                .padding(.top, 12)

                // -- Digital clock --
                Text(self.viewModel.formattedTime(for: context.date))
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                .ultraThinMaterial,
                in: .rect(cornerRadius: 16, style: .continuous)
            )
        }
    }
}
