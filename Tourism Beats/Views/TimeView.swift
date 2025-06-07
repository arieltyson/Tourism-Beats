import SwiftUI

struct TimeView: View {
    @StateObject private var viewModel: TimeViewModel

    init(cityName: String) {
        _viewModel = StateObject(
            wrappedValue: TimeViewModel(cityName: cityName)
        )
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack {

                Spacer()

                // -- Analog clock --
                ClockView(
                    date: context.date,
                    timeZone: viewModel.timeZone
                )
                .frame(width: 120, height: 120)
                .padding()

                // -- Digital clock --
                Text(viewModel.formattedTime(for: context.date))
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Spacer()
            }
            .frame(width: 175, height: 250)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.5))
                    .shadow(radius: 5)
            )
            .padding()
        }
    }
}
