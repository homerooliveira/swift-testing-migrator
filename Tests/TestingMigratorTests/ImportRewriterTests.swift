import Testing
@testable import TestingMigrator
import SwiftSyntax

struct ImportRewriterTests {
    @Test func testImport() throws {
        let source = """
        import XCTest
        """
        let expected = """
        import Testing
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testImportWithComment() throws {
        let source = """
        // Comment
        internal import XCTest
        """
        let expected = """
        // Comment
        internal import Testing
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }
}
