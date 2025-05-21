import Testing
@testable import TestingMigrator
import SwiftSyntax

struct ClassRewriterTests {
    @Test func testClassInheritanceRemoval() throws {
        let source = """
        final class MyTests: XCTestCase {
        }
        """
        let expected = """
        final class MyTests {
        }
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }

    @Test func testClassWithMultipleInheritance() throws {
        let source = """
        class MyTests: XCTestCase, SomeProtocol {
             func testMyTest() {
             }
        }
        """
        let expected = """
        class MyTests: SomeProtocol {
             @Test func testMyTest() {
             }
        }
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }
    
    @Test func testClassWithoutXCTestInheritance() throws {
        let source = """
        class MyClass: SomeClass {
        }
        """
        let expected = """
        class MyClass: SomeClass {
        }
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }
    
    @Test func testClassWithExistingTestAttribute() throws {
        let source = """
        class MyTests: XCTestCase {
            @Test func testExample() {
            }
        }
        """
        let expected = """
        class MyTests {
            @Test func testExample() {
            }
        }
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }
    
    @Test func testClassWithEmptyInheritanceClause() throws {
        let source = """
        class MyTests {
            func testExample() {
            }
        }
        """
        let expected = """
        class MyTests {
            func testExample() {
            }
        }
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }
    
    @Test func testMethodsNotStartingWithTest() throws {
        let source = """
        class MyTests: XCTestCase {
            func setup() {
            }
            func testExample() {
            }
            func helperMethod() {
            }
        }
        """
        let expected = """
        class MyTests {
            func setup() {
            }
            @Test func testExample() {
            }
            func helperMethod() {
            }
        }
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }
    
    @Test func testMultipleTestMethods() throws {
        let source = """
        class MyTests: XCTestCase {
            func testOne() {
            }
            func testTwo() {
            }
            func testThree() {
            }
        }
        """
        let expected = """
        class MyTests {
            @Test func testOne() {
            }
            @Test func testTwo() {
            }
            @Test func testThree() {
            }
        }
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }
    
    @Test func testPreservesLeadingTrivia() throws {
        let source = """
        // My test class
        class MyTests: XCTestCase {
            // Test with a comment
            func testExample() {
            }
        }
        """
        let expected = """
        // My test class
        class MyTests {
            // Test with a comment
            @Test func testExample() {
            }
        }
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent.description == expected)
    }
}
