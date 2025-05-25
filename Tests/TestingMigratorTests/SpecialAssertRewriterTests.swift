import Testing
@testable import TestingMigrator
import SwiftSyntax

struct SpecialAssertRewriterTests {
    @Test func testFail() throws {
        let source = """
        XCTFail()
        """
        let expected = """
        Issue.record()
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent == expected)
    }

    @Test func testFailWithMessage() throws {
        let source = """
        XCTFail("Message")
        """
        let expected = """
        Issue.record("Message")
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent == expected)
    }

    @Test func testFailWithFileAndLine() throws {
        let source = """
        XCTFail(file: #file, line: #line)
        """
        let expected = """
        Issue.record()
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent == expected)
    }

    @Test func testFailWithMessageFileAndLine() throws {
        let source = """
        XCTFail("Message", file: #file, line: #line)
        """
        let expected = """
        Issue.record("Message")
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent == expected)
    }
    
    @Test func testUnwrap() throws {
        let source = """
        let value = try XCTUnwrap(optional)
        """
        let expected = """
        let value = try #require(optional)
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent == expected)
    }

    @Test func testUnwrapWithMessage() throws {
        let source = """
        let value = try XCTUnwrap(optional, "Message")
        """
        let expected = """
        let value = try #require(optional, "Message")
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent == expected)
    }

    @Test func testUnwrapWithFileAndLine() throws {
        let source = """
        let value = try XCTUnwrap(optional, file: #file, line: #line)
        """
        let expected = """
        let value = try #require(optional)
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent == expected)
    }

    @Test func testUnwrapWithMessageFileAndLine() throws {
        let source = """
        let value = try XCTUnwrap(optional, "Message", file: #file, line: #line)
        """
        let expected = """
        let value = try #require(optional, "Message")
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent == expected)
    }
}
