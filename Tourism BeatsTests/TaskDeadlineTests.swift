import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - TaskDeadlineTests

struct TaskDeadlineTests {
    @Test func returnsTheValueWhenTheTaskFinishesInTime() async {
        let task = Task { 42 }

        #expect(await task.value(within: .seconds(5)) == 42)
    }

    @Test func givesUpAndCancelsASlowTask() async {
        let task = Task<Bool, Never> {
            (try? await Task.sleep(for: .seconds(60))) == nil
        }
        let clock = ContinuousClock()

        let start = clock.now
        let value = await task.value(within: .milliseconds(50))

        #expect(value == nil)
        #expect(clock.now - start < .seconds(5))
        // The sleep was interrupted, so the task saw its cancellation.
        #expect(await task.value)
    }
}
