import Foundation

extension Task where Failure == Never {
    /// The task's value if it finishes within `timeout`. Otherwise the task is
    /// cancelled and `nil` is returned, so a slow optional source can't hold up
    /// a result that's already good enough to show.
    func value(within timeout: Duration) async -> Success? {
        await withTaskGroup(of: Success?.self) { group in
            group.addTask { await self.value }
            group.addTask {
                try? await ContinuousClock().sleep(for: timeout)
                return nil
            }

            let first = await group.next() ?? nil
            if first == nil {
                self.cancel()
            }
            group.cancelAll()
            return first
        }
    }
}
