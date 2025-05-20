import Testing
@testable import TestingMigrator
import SwiftSyntax

struct AssertBoolRewriterTests {
    @Test func testAssertTrue() throws {
        let source = """
        XCTAssertTrue(value)
        """
        let expected = """
        #expect(value)
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testAssertTrueWithMessage() throws {
        let source = """
        XCTAssertTrue(value, "Message")
        """
        let expected = """
        #expect(value, "Message")
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }
    
    @Test func testAssertFalse() throws {
        let source = """
        XCTAssertFalse(value)
        """
        let expected = """
        #expect(!value)
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testAssertFalseWithMessage() throws {
        let source = """
        XCTAssertFalse(value, "Message")
        """
        let expected = """
        #expect(!value, "Message")
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testAssertTrueWithFileAndLine() throws {
        let source = """
        XCTAssertTrue(value, file: #file, line: #line)
        """
        let expected = """
        #expect(value)
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testAssertTrueWithMessageFileAndLine() throws {
        let source = """
        XCTAssertTrue(value, "Message", file: #file, line: #line)
        """
        let expected = """
        #expect(value, "Message")
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testAssertFalseWithFileAndLine() throws {
        let source = """
        XCTAssertFalse(value, file: #file, line: #line)
        """
        let expected = """
        #expect(!value)
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testAssertFalseWithMessageFileAndLine() throws {
        let source = """
        XCTAssertFalse(value, "Message", file: #file, line: #line)
        """
        let expected = """
        #expect(!value, "Message")
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }
}
