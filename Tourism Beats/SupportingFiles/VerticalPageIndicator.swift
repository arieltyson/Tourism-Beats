import SwiftUI

/// Shows two small vertical dots “••” and highlights the active page
struct VerticalPageIndicator: View {
    /// 0 = City, 1 = Music
    let activeIndex: Int

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .frame(
                    width: activeIndex == 0 ? 8 : 5,
                    height: activeIndex == 0 ? 8 : 5
                )
                .foregroundColor(activeIndex == 0 ? .white : .gray)
            Circle()
                .frame(
                    width: activeIndex == 1 ? 8 : 5,
                    height: activeIndex == 1 ? 8 : 5
                )
                .foregroundColor(activeIndex == 1 ? .white : .gray)
        }
        .padding(.trailing, 16)
    }
}
