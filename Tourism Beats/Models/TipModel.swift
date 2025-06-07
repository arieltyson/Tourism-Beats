import SwiftUI
import TipKit

@available(iOS 17.0, *)
struct TipModel: Tip {
    static let didVisitMusicRecommendation = Event(
        id: "didVisitMusicRecommendation"
    )

    var rules: [Rule] {
        #Rule(Self.didVisitMusicRecommendation) {
            $0.donations.count == 0
        }
    }

    var title: Text {
        Text("Swipe left")
            .foregroundStyle(.cyan)
    }

    var message: Text? {
        Text("Swipe left to discover the city's top tune.")
            .foregroundStyle(.indigo)
    }

    var image: Image? {
        Image(systemName: "hand.draw.fill")
    }
}
