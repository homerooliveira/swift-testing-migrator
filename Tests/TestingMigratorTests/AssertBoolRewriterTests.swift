import SwiftSyntax
import Testing

@testable import TestingMigrator

struct AssertBoolRewriterTests {
    @Test func testAssertTrue() throws {
        let source = """
            XCTAssertTrue(value)
            """
        let expected = """
            #expect(value)
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertTrueWithMessage() throws {
        let source = """
            XCTAssertTrue(value, "Message")
            """
        let expected = """
            #expect(value, "Message")
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertFalse() throws {
        let source = """
            XCTAssertFalse(value)
            """
        let expected = """
            #expect(!value)
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertFalseWithExpression() throws {
        let source = """
            XCTAssertFalse(value == true)
            """
        let expected = """
            #expect(!(value == true))
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertFalseWithMessage() throws {
        let source = """
            XCTAssertFalse(value, "Message")
            """
        let expected = """
            #expect(!value, "Message")
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertTrueWithFileAndLine() throws {
        let source = """
            XCTAssertTrue(value, file: #file, line: #line)
            """
        let expected = """
            #expect(value)
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertTrueWithMessageFileAndLine() throws {
        let source = """
            XCTAssertTrue(value, "Message", file: #file, line: #line)
            """
        let expected = """
            #expect(value, "Message")
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertFalseWithFileAndLine() throws {
        let source = """
            XCTAssertFalse(value, file: #file, line: #line)
            """
        let expected = """
            #expect(!value)
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertFalseWithMessageFileAndLine() throws {
        let source = """
            XCTAssertFalse(value, "Message", file: #file, line: #line)
            """
        let expected = """
            #expect(!value, "Message")
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }
}
