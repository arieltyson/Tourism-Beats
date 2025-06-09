import SwiftUI

/// Two-state vertical pager between CityView ↔ MusicView
struct CityContainerView: View {
    let city: CityModel
    @State private var showMusic = false

    var body: some View {
        ZStack {
            // ── City page (slides out upward) ────────────────────────────
            CityView(city: city)
                .opacity(showMusic ? 0 : 1)
                .transition(.move(edge: .top))

            // ── Music page (slides in from below) ────────────────────────
            MusicView(city: city, fallbackView: FallbackMusicView())
                .opacity(showMusic ? 1 : 0)
                .transition(.move(edge: .bottom))
        }
        .animation(.easeInOut, value: showMusic)
        .highPriorityGesture(
            DragGesture(minimumDistance: 30)
                .onEnded { g in
                    let dx = abs(g.translation.width)
                    let dy = g.translation.height
                    guard dx < abs(dy) else { return }
                    withAnimation {
                        showMusic = (dy < 0)
                    }
                }
        )
        .overlay(
            VerticalPageIndicator(activeIndex: showMusic ? 1 : 0)
                .padding(.trailing, 16),
            alignment: .trailing
        )
        .navigationBarHidden(false)
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if showMusic {
                    Text(city.country.flag)
                        .font(.system(size: 40))
                        .transition(.opacity.animation(.easeInOut))
                }
            }
        }
    }
}
