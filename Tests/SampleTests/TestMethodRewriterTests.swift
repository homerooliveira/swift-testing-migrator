import Testing
@testable import TestingMigrator
import SwiftSyntax

struct TestMethodRewriterTests {
    @Test func testAddAnotationToMethod() throws {
        let source = """
        func testSomething() async throws {
        }
        """
        let expected = """
        @Test func testSomething() async throws {
        }
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testDontAddAnotationToExistingTest() throws {
        let source = """
        @Test func testSomething() {
        }
        """
        let expected = """
        @Test func testSomething() {
        }
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testDontAddAnotationToMethodWitoutTestPrefix() throws {
        let source = """
        func something() {
        }
        """
        let expected = """
        func something() {
        }
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }
}
