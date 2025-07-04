import SwiftSyntax
import Testing

@testable import TestingMigrator

struct AssertThrowRewriterTests {
    @Test func testAssertThrowsError() throws {
        let source = """
            XCTAssertThrowsError(try something())
            """
        let expected = """
            #expect(throws: (any Error).self) { try something() }
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertThrowsErrorWithMessage() throws {
        let source = """
            XCTAssertThrowsError(try something(), "Message")
            """
        let expected = """
            #expect(throws: (any Error).self, "Message") { try something() }
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertNoThrow() throws {
        let source = """
            XCTAssertNoThrow(try something())
            """
        let expected = """
            #expect(throws: Never.self) { try something() }
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertNoThrowWithMessage() throws {
        let source = """
            XCTAssertNoThrow(try something(), "Message")
            """
        let expected = """
            #expect(throws: Never.self, "Message") { try something() }
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertThrowsErrorWithFileAndLine() throws {
        let source = """
            XCTAssertThrowsError(try something(), file: #file, line: #line)
            """
        let expected = """
            #expect(throws: (any Error).self) { try something() }
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertThrowsErrorWithMessageFileAndLine() throws {
        let source = """
            XCTAssertThrowsError(try something(), "Message", file: #file, line: #line)
            """
        let expected = """
            #expect(throws: (any Error).self, "Message") { try something() }
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testAssertThrowsErrorWithTrailingClosure() throws {
        let source = """
            XCTAssertThrowsError(try something()) { error in
                XCTAssertEqual(error.localizedDescription, "Message")
                XCTAssertTrue(error is CocoaError)
            }
            """
        let expected = """
            let error = #expect(throws: (any Error).self) { try something() }
            #expect(error?.localizedDescription == "Message")
            #expect(error is CocoaError)
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test
    func testAssertThrowsErrorWithMessageAndTrailingClosure() throws {
        let source = """
            XCTAssertThrowsError(try something(), "Message") { error in
                #expect(error is MyError)
            }
            """
        let expected = """
            let error = #expect(throws: (any Error).self, "Message") { try something() }
            #expect(error is MyError)
            """
        let modifiedContent = Rewriter(useClass: false).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }
}
