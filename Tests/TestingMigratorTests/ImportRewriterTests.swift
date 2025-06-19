import SwiftSyntax
import Testing

@testable import TestingMigrator

struct ImportRewriterTests {
    @Test func testImport() throws {
        let source = """
            import XCTest
            """
        let expected = """
            import Testing
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
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
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }
}
