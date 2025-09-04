import SwiftUI

/// Vertical page dots. Defaults to 3 pages.
/// `activeIndex` is 0-based.
struct VerticalPageIndicator: View {
    let activeIndex: Int
    let count: Int

    init(activeIndex: Int, count: Int = 3) {
        self.activeIndex = activeIndex
        self.count = count
    }

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .frame(
                        width: activeIndex == i ? 10 : 6,
                        height: activeIndex == i ? 10 : 6
                    )
                    .foregroundColor(activeIndex == i ? .white : .white.opacity(0.4))
                    .shadow(
                        color: activeIndex == i ? .black.opacity(0.3) : .clear,
                        radius: activeIndex == i ? 2 : 0,
                        x: 0,
                        y: 1
                    )
                    .animation(.easeInOut(duration: 0.2), value: activeIndex)
            }
        }
    }
}
