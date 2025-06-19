import SwiftSyntax
import Testing

@testable import TestingMigrator

struct AssertRewriterTests {
    @Test func testAssert() throws {
        let source = """
            XCTAssert(value == true)
            """
        let expected = """
            #expect(value == true)
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertWithMessage() throws {
        let source = """
            XCTAssert(value == true, "Message")
            """
        let expected = """
            #expect(value == true, "Message")
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertWithFileAndLine() throws {
        let source = """
            XCTAssert(value == true, file: #file, line: #line)
            """
        let expected = """
            #expect(value == true)
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertWithMessageFileAndLine() throws {
        let source = """
            XCTAssert(value == true, "Message", file: #file, line: #line)
            """
        let expected = """
            #expect(value == true, "Message")
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }
}
