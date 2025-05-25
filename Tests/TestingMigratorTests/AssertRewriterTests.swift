import Testing
@testable import TestingMigrator
import SwiftSyntax

struct AssertRewriterTests {
    @Test func testAssert() throws {
        let source = """
        XCTAssert(value == true)
        """
        let expected = """
        #expect(value == true)
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent == expected)
    }

    @Test func testAssertWithMessage() throws {
        let source = """
        XCTAssert(value == true, "Message")
        """
        let expected = """
        #expect(value == true, "Message")
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent == expected)
    }

    @Test func testAssertWithFileAndLine() throws {
        let source = """
        XCTAssert(value == true, file: #file, line: #line)
        """
        let expected = """
        #expect(value == true)
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent == expected)
    }

    @Test func testAssertWithMessageFileAndLine() throws {
        let source = """
        XCTAssert(value == true, "Message", file: #file, line: #line)
        """
        let expected = """
        #expect(value == true, "Message")
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent == expected)
    }
}
