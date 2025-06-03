import Testing
@testable import TestingMigrator
import SwiftSyntax

struct AssertIdenticalRewriterTests {
    @Test func testAssertIdentical() throws {
        let source = """
        XCTAssertIdentical(a, b)
        """
        let expected = """
        #expect(a === b)
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertIdenticalWithMessage() throws {
        let source = """
        XCTAssertIdentical(a, b, "Message")
        """
        let expected = """
        #expect(a === b, "Message")
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertNotIdentical() throws {
        let source = """
        XCTAssertNotIdentical(a, b)
        """
        let expected = """
        #expect(a !== b)
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertNotIdenticalWithMessage() throws {
        let source = """
        XCTAssertNotIdentical(a, b, "Message")
        """
        let expected = """
        #expect(a !== b, "Message")
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertIdenticalWithFileAndLine() throws {
        let source = """
        XCTAssertIdentical(a, b, file: #file, line: #line)
        """
        let expected = """
        #expect(a === b)
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertIdenticalWithMessageFileAndLine() throws {
        let source = """
        XCTAssertIdentical(a, b, "Message", file: #file, line: #line)
        """
        let expected = """
        #expect(a === b, "Message")
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertNotIdenticalWithFileAndLine() throws {
        let source = """
        XCTAssertNotIdentical(a, b, file: #file, line: #line)
        """
        let expected = """
        #expect(a !== b)
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertNotIdenticalWithMessageFileAndLine() throws {
        let source = """
        XCTAssertNotIdentical(a, b, "Message", file: #file, line: #line)
        """
        let expected = """
        #expect(a !== b, "Message")
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }
}
