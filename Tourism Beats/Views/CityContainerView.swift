import SwiftUI

/// Three-state vertical pager: 0 = City, 1 = Music, 2 = Advisories
struct CityContainerView: View {
    let city: CityModel

    @State private var pageIndex: Int = 0  // 0…2
    @State private var dragOffset: CGFloat = 0
    @State private var isPaging: Bool = false  // when true, our drag takes precedence

    var body: some View {
        GeometryReader { geo in
            // 1) Background paints under transparent bars
            backgroundForCurrentPage
                .ignoresSafeArea()

            // 2) Foreground pages live inside the safe area, move interactively
            let pageHeight = geo.size.height
            let pageWidth = geo.size.width

            ZStack {
                CityView(city: city)
                    .frame(width: pageWidth, height: pageHeight)
                    .offset(y: offset(for: 0, height: pageHeight))

                MusicView(city: city, fallbackView: FallbackMusicView())
                    .frame(width: pageWidth, height: pageHeight)
                    .offset(y: offset(for: 1, height: pageHeight))

                AdvisoriesView(city: city)
                    .frame(width: pageWidth, height: pageHeight)
                    .offset(y: offset(for: 2, height: pageHeight))
            }
            .clipped()  // hide off-screen pages cleanly
            .contentShape(Rectangle())
            .animation(
                .interactiveSpring(response: 0.35, dampingFraction: 0.85),
                value: pageIndex
            )
            .highPriorityGesture(
                DragGesture(minimumDistance: 12)  // ↓ lighter than before
                    .onChanged { value in
                        // Only engage if the drag is vertically dominant (allow some diagonal)
                        if !isPaging {
                            let v = abs(value.translation.height)
                            let h = abs(value.translation.width)
                            guard v > h * 0.7 else { return }  // ↓ less strict than 1.0x
                            isPaging = true
                        }
                        dragOffset = value.translation.height
                    }
                    .onEnded { value in
                        defer {
                            dragOffset = 0
                            isPaging = false
                        }

                        // Vertical dominance check again on end
                        let v = abs(value.translation.height)
                        let h = abs(value.translation.width)
                        guard v > h * 0.7 else { return }

                        let height = pageHeight
                        // Distance threshold: ~14% of height, clamped for consistency across devices
                        let base = height * 0.14
                        let threshold = min(140, max(80, base))

                        let dy = value.translation.height
                        let commitByDistance = abs(dy) > threshold

                        // Velocity/prediction fallback: quick flicks commit even if distance short
                        let predicted = value.predictedEndTranslation.height
                        let sameDirection =
                            (dy >= 0 && predicted >= 0)
                            || (dy <= 0 && predicted <= 0)
                        let commitByVelocity =
                            sameDirection && abs(predicted) > threshold * 0.6

                        if commitByDistance || commitByVelocity {
                            if dy < 0, pageIndex < 2 {
                                pageIndex += 1
                            }  // swipe up → next
                            else if dy > 0, pageIndex > 0 {
                                pageIndex -= 1
                            }  // swipe down → prev
                        }
                    }
            )
            .overlay(
                VerticalPageIndicator(activeIndex: pageIndex, count: 3)
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
                if pageIndex != 0 {
                    Text(city.country.flag)
                        .font(.system(size: 40))
                        .transition(.opacity.animation(.easeInOut))
                }
            }
        }
    }

    // Interactive offset (current page + neighbors) with live drag
    private func offset(for index: Int, height: CGFloat) -> CGFloat {
        CGFloat(index - pageIndex) * height + dragOffset
    }

    // Deterministic gradient per page (no result-builder logic).
    private var backgroundForCurrentPage: some View {
        let all = GradientProvider.gradients
        let base = city.id.hashValue
        let seed: Int
        switch pageIndex {
        case 0: seed = base &* 31
        case 1: seed = base &* 47
        default: seed = base &* 59
        }
        let idx = abs(seed) % all.count
        return all[idx]
    }
}
