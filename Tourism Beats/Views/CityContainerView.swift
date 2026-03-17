import SwiftUI

struct CityContainerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let city: CityModel

    @State private var pageIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isPaging: Bool = false
    @State private var containerSize: CGSize = .zero
    @State private var haptic = HapticTrigger()

    private let pageCount = 3

    var body: some View {
        ZStack {
            self.backgroundForCurrentPage
                .ignoresSafeArea()
                .motionSensitiveAnimation(
                    .easeInOut(duration: 0.4),
                    reduced: .none,
                    value: self.pageIndex
                )

            ZStack {
                CityView(city: self.city)
                    .containerRelativeFrame([.horizontal, .vertical])
                    .offset(y: self.offset(for: 0))

                MusicView(city: self.city, fallbackView: FallbackMusicView())
                    .containerRelativeFrame([.horizontal, .vertical])
                    .offset(y: self.offset(for: 1))

                AdvisoriesView(city: self.city)
                    .containerRelativeFrame([.horizontal, .vertical])
                    .offset(y: self.offset(for: 2))
            }
            .clipped()
            .contentShape(.rect)
            .highPriorityGesture(self.pagingGesture)
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { newSize in
                self.containerSize = newSize
            }
            .motionSensitiveAnimation(
                .interactiveSpring(response: 0.35, dampingFraction: 0.85),
                reduced: .none,
                value: self.pageIndex
            )

            VerticalIconPageIndicator(
                activeIndex: self.pageIndex,
                onSelect: { index in
                    self.selectPage(index)
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            .padding(.trailing, 12)
        }
        .sensoryFeedback(self.haptic.feedback, trigger: self.haptic)
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(self.city.country.flag)
                    .font(.largeTitle)
                    .opacity(self.pageIndex != 0 ? 1 : 0)
                    .motionSensitiveAnimation(
                        .easeInOut,
                        reduced: .none,
                        value: self.pageIndex
                    )
            }
        }
    }

    // MARK: - Offset Calculation

    private func offset(for index: Int) -> CGFloat {
        CGFloat(index - self.pageIndex) * self.containerSize.height + self.dragOffset
    }

    private func selectPage(_ index: Int) {
        guard index != self.pageIndex else { return }

        self.pageIndex = index
        self.haptic.fire(.pageChange)
    }

    // MARK: - Paging Gesture

    private var pagingGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                if !self.isPaging {
                    let vertical = abs(value.translation.height)
                    let horizontal = abs(value.translation.width)
                    guard vertical > horizontal * 0.7 else { return }
                    self.isPaging = true
                }
                self.dragOffset = value.translation.height
            }
            .onEnded { value in
                defer {
                    self.dragOffset = 0
                    self.isPaging = false
                }

                let vertical = abs(value.translation.height)
                let horizontal = abs(value.translation.width)
                guard vertical > horizontal * 0.7 else { return }

                let height = self.containerSize.height
                let base = height * 0.14
                let threshold = min(140, max(80, base))

                let drag = value.translation.height
                let predicted = value.predictedEndTranslation.height
                let sameDirection =
                    (drag >= 0 && predicted >= 0)
                    || (drag <= 0 && predicted <= 0)
                let commitByDistance = abs(drag) > threshold
                let commitByVelocity =
                    sameDirection && abs(predicted) > threshold * 0.6

                if commitByDistance || commitByVelocity {
                    if drag < 0, self.pageIndex < self.pageCount - 1 {
                        self.selectPage(self.pageIndex + 1)
                    } else if drag > 0, self.pageIndex > 0 {
                        self.selectPage(self.pageIndex - 1)
                    }
                }
            }
    }

    // MARK: - Background

    private var backgroundForCurrentPage: some View {
        let all = GradientProvider.gradients
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
