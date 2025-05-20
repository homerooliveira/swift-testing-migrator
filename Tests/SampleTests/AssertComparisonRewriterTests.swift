import Testing
@testable import TestingMigrator
import SwiftSyntax

struct AssertComparisonRewriterTests {
    @Test func testAssertGreaterThan() throws {
        let source = """
        XCTAssertGreaterThan(a, b)
        """
        let expected = """
        #expect(a > b)
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testAssertGreaterThanOrEqual() throws {
        let source = """
        XCTAssertGreaterThanOrEqual(a, b)
        """
        let expected = """
        #expect(a >= b)
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }
    
    @Test func testAssertLessThan() throws {
        let source = """
        XCTAssertLessThan(a, b)
        """
        let expected = """
        #expect(a < b)
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testAssertLessThanOrEqual() throws {
        let source = """
        XCTAssertLessThanOrEqual(a, b)
        """
        let expected = """
        #expect(a <= b)
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testAssertGreaterThanWithFileAndLine() throws {
        let source = """
        XCTAssertGreaterThan(a, b, file: #file, line: #line)
        """
        let expected = """
        #expect(a > b)
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testAssertGreaterThanWithMessageFileAndLine() throws {
        let source = """
        XCTAssertGreaterThan(a, b, "Message", file: #file, line: #line)
        """
        let expected = """
        #expect(a > b, "Message")
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testAssertLessThanWithFileAndLine() throws {
        let source = """
        XCTAssertLessThan(a, b, file: #file, line: #line)
        """
        let expected = """
        #expect(a < b)
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testAssertLessThanWithMessageFileAndLine() throws {
        let source = """
        XCTAssertLessThan(a, b, "Message", file: #file, line: #line)
        """
        let expected = """
        #expect(a < b, "Message")
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testAssertGreaterThanOrEqualWithFileAndLine() throws {
        let source = """
        XCTAssertGreaterThanOrEqual(a, b, file: #file, line: #line)
        """
        let expected = """
        #expect(a >= b)
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testAssertGreaterThanOrEqualWithMessageFileAndLine() throws {
        let source = """
        XCTAssertGreaterThanOrEqual(a, b, "Message", file: #file, line: #line)
        """
        let expected = """
        #expect(a >= b, "Message")
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testAssertLessThanOrEqualWithFileAndLine() throws {
        let source = """
        XCTAssertLessThanOrEqual(a, b, file: #file, line: #line)
        """
        let expected = """
        #expect(a <= b)
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testAssertLessThanOrEqualWithMessageFileAndLine() throws {
        let source = """
        XCTAssertLessThanOrEqual(a, b, "Message", file: #file, line: #line)
        """
        let expected = """
        #expect(a <= b, "Message")
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }
}
