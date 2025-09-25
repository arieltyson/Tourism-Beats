import SwiftUI

struct CityContainerView: View {
    let city: CityModel

    @State private var pageIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isPaging: Bool = false

    var body: some View {
        GeometryReader { geo in
            self.backgroundForCurrentPage
                .ignoresSafeArea()

            let pageHeight = geo.size.height
            let pageWidth = geo.size.width

            ZStack {
                CityView(city: self.city)
                    .frame(width: pageWidth, height: pageHeight)
                    .offset(y: self.offset(for: 0, height: pageHeight))

                MusicView(city: self.city, fallbackView: FallbackMusicView())
                    .frame(width: pageWidth, height: pageHeight)
                    .offset(y: self.offset(for: 1, height: pageHeight))

                AdvisoriesView(city: self.city)
                    .frame(width: pageWidth, height: pageHeight)
                    .offset(y: self.offset(for: 2, height: pageHeight))
            }
            .clipped()
            .contentShape(Rectangle())
            .animation(
                .interactiveSpring(response: 0.35, dampingFraction: 0.85),
                value: self.pageIndex
            )
            .highPriorityGesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        if !self.isPaging {
                            let v = abs(value.translation.height)
                            let h = abs(value.translation.width)
                            guard v > h * 0.7 else { return }
                            self.isPaging = true
                        }
                        self.dragOffset = value.translation.height
                    }
                    .onEnded { value in
                        defer {
                            dragOffset = 0
                            isPaging = false
                        }

                        let v = abs(value.translation.height)
                        let h = abs(value.translation.width)
                        guard v > h * 0.7 else { return }

                        let height = pageHeight
                        let base = height * 0.14
                        let threshold = min(140, max(80, base))

                        let dy = value.translation.height
                        let predicted = value.predictedEndTranslation.height
                        let sameDirection =
                            (dy >= 0 && predicted >= 0)
                            || (dy <= 0 && predicted <= 0)
                        let commitByDistance = abs(dy) > threshold
                        let commitByVelocity =
                            sameDirection && abs(predicted) > threshold * 0.6

                        if commitByDistance || commitByVelocity {
                            if dy < 0, self.pageIndex < 2 {
                                self.pageIndex += 1
                            } else if dy > 0, self.pageIndex > 0 {
                                self.pageIndex -= 1
                            }
                        }
                    }
            )
            .overlay(
                VerticalPageIndicator(activeIndex: self.pageIndex, count: 3)
                    .padding(.trailing, max(8, geo.safeAreaInsets.trailing + 4))
                    .padding(.vertical, max(60, geo.safeAreaInsets.top + 40))
                    .frame(maxHeight: .infinity),
                alignment: .trailing
            )
        }
        .navigationBarHidden(false)
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if self.pageIndex != 0 {
                    Text(self.city.country.flag)
                        .font(.system(size: 40))
                        .transition(.opacity.animation(.easeInOut))
                }
            }
        }
    }

    private func offset(for index: Int, height: CGFloat) -> CGFloat {
        CGFloat(index - self.pageIndex) * height + self.dragOffset
    }

    private var backgroundForCurrentPage: some View {
        let all = GradientProvider.gradients
        // Use bitPattern to avoid overflow on Int.min when taking abs.
        let base = UInt(bitPattern: self.city.id.hashValue)
        let seed: UInt =
            switch self.pageIndex {
            case 0: base &* 31
            case 1: base &* 47
            default: base &* 59
            }
        let idx = Int(seed % UInt(all.count))
        return all[idx]
    }
}
