import SwiftSyntax
import Testing

@testable import TestingMigrator

struct AssertEqualRewriterTests {
    @Test func testAssertEqual() throws {
        let source = """
            XCTAssertEqual(a, b)
            """
        let expected = """
            #expect(a == b)
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertEqualWithMessage() throws {
        let source = """
            XCTAssertEqual(a, b, "Message")
            """
        let expected = """
            #expect(a == b, "Message")
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertNotEqual() throws {
        let source = """
            XCTAssertNotEqual(a, b)
            """
        let expected = """
            #expect(a != b)
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertNotEqualWithMessage() throws {
        let source = """
            XCTAssertNotEqual(a, b, "Message")
            """
        let expected = """
            #expect(a != b, "Message")
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertEqualWithFileAndLine() throws {
        let source = """
            XCTAssertEqual(a, b, file: #file, line: #line)
            """
        let expected = """
            #expect(a == b)
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertEqualWithMessageFileAndLine() throws {
        let source = """
            XCTAssertEqual(a, b, "Message", file: #file, line: #line)
            """
        let expected = """
            #expect(a == b, "Message")
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }
}
