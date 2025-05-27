import Testing
@testable import TestingMigrator
import SwiftSyntax

struct ClassRewriterTests {
    @Test func testStructWithOpenClass() throws {
        let source = """
        open class MyTests: XCTestCase {
            func testMyTest() {
            }
        }
        """
        let expected = """
        struct MyTests {
            @Test func testMyTest() {
            }
        }
        """
        let modifiedContent = Rewriter(.init(useClass: false)).rewrite(source: source)
        #expect(modifiedContent == expected)
    }

    @Test func testStructWithFinalClass() throws {
        let source = """
        final class MyTests: XCTestCase {
            func testMyTest() {
            }
        }
        """
        let expected = """
        struct MyTests {
            @Test func testMyTest() {
            }
        }
        """
        let modifiedContent = Rewriter(.init(useClass: false)).rewrite(source: source)
        #expect(modifiedContent == expected)
    }

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
        #expect(modifiedContent == expected)
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
        #expect(modifiedContent == expected)
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
        #expect(modifiedContent == expected)
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
        #expect(modifiedContent == expected)
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
        #expect(modifiedContent == expected)
    }
    
    @Test func testMethodsNotStartingWithTest() throws {
        let source = """
        class MyTests: XCTestCase {
            override func setUp() async {
            }
            override func setUpWithError() throws {
            }
            func testExample() {
            }
            func helperMethod() {
            }
        }
        """
        let expected = """
        class MyTests {
            init() async {
            }
            init() throws {
            }
            @Test func testExample() {
            }
            func helperMethod() {
            }
        }
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        #expect(modifiedContent == expected)
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
        #expect(modifiedContent == expected)
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
        #expect(modifiedContent == expected)
    }
}
