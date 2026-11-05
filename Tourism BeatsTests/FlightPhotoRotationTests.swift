import Foundation
import Testing
@testable import Tourism_Beats

struct FlightPhotoRotationTests {
    /// A turn every photo count divides, so each count's rounds begin here.
    private let start = Date(timeIntervalSinceReferenceDate: 1_200 * FlightCountdownStyle.photoInterval)
    private let seed = UUID(uuidString: "00000000-0000-0000-0000-000000000042")!

    private func turns(_ count: Int, rounds: Int, seed: UUID? = nil) -> [Int] {
        (0..<(count * rounds)).map {
            FlightPhotoRotation.index(
                count: count, seed: seed ?? self.seed,
                at: start.addingTimeInterval(Double($0) * FlightCountdownStyle.photoInterval)
            )
        }
    }

    @Test func everyPhotoHasOneTurnEachRoundAndNeverTwiceInARow() {
        for count in 2...FlightCountdownStyle.maximumPhotoCount {
            let shown = turns(count, rounds: 50)
            for round in stride(from: 0, to: shown.count, by: count) {
                #expect(Set(shown[round..<round + count]) == Set(0..<count))
            }
            #expect(zip(shown, shown.dropFirst()).allSatisfy { $0 != $1 })
        }
    }

    @Test func theOrderIsShuffledAndRepeatable() {
        let shown = turns(4, rounds: 20)
        #expect(shown == turns(4, rounds: 20))
        let rounds = stride(from: 0, to: shown.count, by: 4).map { Array(shown[$0..<$0 + 4]) }
        #expect(Set(rounds).count > 1)
        #expect(shown != turns(4, rounds: 20, seed: UUID(uuidString: "00000000-0000-0000-0000-000000000043")!))
    }

    @Test func aPhotoHoldsForItsWholeTurn() {
        let late = start.addingTimeInterval(FlightCountdownStyle.photoInterval - 1)
        #expect(FlightPhotoRotation.index(count: 4, seed: seed, at: start) == FlightPhotoRotation.index(count: 4, seed: seed, at: late))
    }

    @Test func oneOrNoPhotosNeedNoTurns() {
        #expect(FlightPhotoRotation.index(count: 1, seed: seed, at: start) == 0)
        #expect(FlightPhotoRotation.index(count: 0, seed: seed, at: start) == 0)
    }
}
