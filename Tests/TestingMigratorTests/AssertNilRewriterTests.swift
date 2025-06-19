import SwiftSyntax
import Testing

@testable import TestingMigrator

struct AssertNilRewriterTests {
    @Test func testAssertNil() throws {
        let source = """
            XCTAssertNil(value)
            """
        let expected = """
            #expect(value == nil)
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertNilWithMessage() throws {
        let source = """
            XCTAssertNil(value, "Message")
            """
        let expected = """
            #expect(value == nil, "Message")
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertNotNil() throws {
        let source = """
            XCTAssertNotNil(value)
            """
        let expected = """
            #expect(value != nil)
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertNotNilWithMessage() throws {
        let source = """
            XCTAssertNotNil(value, "Message")
            """
        let expected = """
            #expect(value != nil, "Message")
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertNilWithFileAndLine() throws {
        let source = """
            XCTAssertNil(value, file: #file, line: #line)
            """
        let expected = """
            #expect(value == nil)
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }
}
