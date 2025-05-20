import Testing
@testable import TestingMigrator
import SwiftSyntax

@Suite(.disabled("TODO: Add implementation for this test"))
struct AssertThrowRewriterTests {
    @Test func testAssertThrowsError() throws {
        let source = """
        XCTAssertThrowsError(try something())
        """
        let expected = """
        #expect(throws: try something())
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testAssertThrowsErrorWithMessage() throws {
        let source = """
        XCTAssertThrowsError(try something(), "Message")
        """
        let expected = """
        #expect(throws: try something(), "Message")
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }
    
    @Test func testAssertNoThrow() throws {
        let source = """
        XCTAssertNoThrow(try something())
        """
        let expected = """
        #expect(try something())
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testAssertNoThrowWithMessage() throws {
        let source = """
        XCTAssertNoThrow(try something(), "Message")
        """
        let expected = """
        #expect(try something(), "Message")
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testAssertThrowsErrorWithFileAndLine() throws {
        let source = """
        XCTAssertThrowsError(try something(), file: #file, line: #line)
        """
        let expected = """
        #expect(throws: try something())
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testAssertThrowsErrorWithMessageFileAndLine() throws {
        let source = """
        XCTAssertThrowsError(try something(), "Message", file: #file, line: #line)
        """
        let expected = """
        #expect(throws: try something(), "Message")
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }
}
