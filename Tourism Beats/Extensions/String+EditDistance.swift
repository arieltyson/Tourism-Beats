// MARK: - Edit Distance

extension String {
    /// The number of single-character insertions, deletions, substitutions,
    /// or swaps of neighbouring characters needed to turn this string into
    /// `other`. Swaps count once, so "Prais" is one edit from "Paris".
    func editDistance(to other: String) -> Int {
        let source = Array(self)
        let target = Array(other)
        guard !source.isEmpty else { return target.count }
        guard !target.isEmpty else { return source.count }

        var previousRow: [Int] = []
        var row = Array(0 ... target.count)

        for sourceIndex in 1 ... source.count {
            let rowBefore = row
            row = [sourceIndex] + Array(repeating: 0, count: target.count)

            for targetIndex in 1 ... target.count {
                let cost = source[sourceIndex - 1] == target[targetIndex - 1] ? 0 : 1
                row[targetIndex] = Swift.min(
                    rowBefore[targetIndex] + 1,
                    row[targetIndex - 1] + 1,
                    rowBefore[targetIndex - 1] + cost
                )

                if sourceIndex > 1, targetIndex > 1,
                   source[sourceIndex - 1] == target[targetIndex - 2],
                   source[sourceIndex - 2] == target[targetIndex - 1]
                {
                    row[targetIndex] = Swift.min(row[targetIndex], previousRow[targetIndex - 2] + 1)
                }
            }

            previousRow = rowBefore
        }

        return row[target.count]
    }
}
