import Testing
import Foundation


// MARK: - String Diff Assertion

/// Custom assertion that shows detailed differences between two strings
/// - Parameters:
///   - actual: The actual string value
///   - expected: The expected string value
///   - message: Additional message to display on failure
///   - sourceLocation: The source location where the assertion is called
func expectStringDiff(
    _ actual: String,
    _ expected: String,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    guard actual != expected else { return }

    let differ = StringDiff()
    let diff = differ.createDiff(actual: actual, expected: expected)

    Issue.record(Comment(rawValue: diff), sourceLocation: sourceLocation)
}

// MARK: - String Diff Engine

private struct StringDiff {
    func createDiff(actual: String, expected: String) -> String {
        // Split into lines for comparison
        let actualLines = actual.components(separatedBy: .newlines)
        let expectedLines = expected.components(separatedBy: .newlines)

        // Use CollectionDifference to compute the diff
        let difference = expectedLines.difference(from: actualLines)

        return formatDifference(difference, actualLines: actualLines, expectedLines: expectedLines)
    }

    private func formatDifference(
        _ difference: CollectionDifference<String>,
        actualLines: [String],
        expectedLines: [String]
    ) -> String {
        // Build a comprehensive diff view
        let allLines = buildUnifiedView(
            actualLines: actualLines,
            expectedLines: expectedLines,
            difference: difference
        )

        return allLines.joined(separator: "\n")
    }

    private func buildUnifiedView(
        actualLines: [String],
        expectedLines: [String],
        difference: CollectionDifference<String>
    ) -> [String] {
        var result: [String] = [""]

        // Create a map of insertions and removals for easier lookup
        var insertions: [Int: String] = [:]
        var removals: Set<Int> = []

        for change in difference {
            switch change {
            case .insert(let offset, let element, _):
                insertions[offset] = element
            case .remove(let offset, _, _):
                removals.insert(offset)
            }
        }

        // Process the actual lines, marking removals and identifying modifications
        var actualIndex = 0
        var expectedIndex = 0

        while actualIndex < actualLines.count || expectedIndex < expectedLines.count {
            let isActualRemoved = removals.contains(actualIndex)
            let hasInsertion = insertions[expectedIndex] != nil

            if actualIndex < actualLines.count && !isActualRemoved {
                // Line exists in both - skip unchanged lines
                actualIndex += 1
                expectedIndex += 1
            } else if actualIndex < actualLines.count && isActualRemoved && hasInsertion {
                // Show as deletion + addition
                let actualLine = actualLines[actualIndex]
                let expectedLine = insertions[expectedIndex]!

                result.append("- \(visualizeWhitespace(actualLine))")
                result.append("+ \(visualizeWhitespace(expectedLine))")

                actualIndex += 1
                expectedIndex += 1
            } else if actualIndex < actualLines.count && isActualRemoved {
                // Pure deletion
                result.append("- \(visualizeWhitespace(actualLines[actualIndex]))")
                actualIndex += 1
            } else if hasInsertion {
                // Pure insertion
                result.append("+ \(visualizeWhitespace(insertions[expectedIndex]!))")
                expectedIndex += 1
            } else {
                // This shouldn't happen in a well-formed diff
                break
            }
        }

        return result
    }

    /// Visualizes whitespace characters for better diff display
    private func visualizeWhitespace(_ string: String) -> String {
        return string
            .replacingOccurrences(of: " ", with: "·")      // Middle dot for spaces
            .replacingOccurrences(of: "\t", with: "→")     // Arrow for tabs
            .replacingOccurrences(of: "\r", with: "↩")     // Return symbol for carriage returns
    }

}

// MARK: - CollectionDifference Extensions for Convenience

extension CollectionDifference {
    /// Returns all insertion changes
    var insertions: [CollectionDifference<ChangeElement>.Change] {
        compactMap { change in
            if case .insert = change { return change }
            return nil
        }
    }

    /// Returns all removal changes
    var removals: [CollectionDifference<ChangeElement>.Change] {
        compactMap { change in
            if case .remove = change { return change }
            return nil
        }
    }
}
