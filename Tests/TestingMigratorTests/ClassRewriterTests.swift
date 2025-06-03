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
        expectStringDiff(modifiedContent, expected)
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
        expectStringDiff(modifiedContent, expected)
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
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testClassWithStoredPropertyAndMethod() throws {
        let source = """
        final class MyTests: XCTestCase {
            var foo = Foo()
            func testFoo() {
                XCTAssertThrowsError(try something(), "Message")
                XCTAssertThrowsError(try foo.bar, "Message")
            }

            func something() {
            }
        }
        """
        let expected = """
        final class MyTests {
            var foo = Foo()
            @Test func testFoo() {
                #expect(throws: (any Error).self, "Message") { try self.something() }
                #expect(throws: (any Error).self, "Message") { try self.foo.bar }
            }

            func something() {
            }
        }
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
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
        expectStringDiff(modifiedContent, expected)
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
        expectStringDiff(modifiedContent, expected)
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
        expectStringDiff(modifiedContent, expected)
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
        expectStringDiff(modifiedContent, expected)
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
        expectStringDiff(modifiedContent, expected)
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
        expectStringDiff(modifiedContent, expected)
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
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testClassWithMultipleModifiers() throws {
        let source = """
        public final class MyTests: XCTestCase {
            func testMyTest() {}
        }
        """
        let expected = """
        public struct MyTests {
            @Test func testMyTest() {}
        }
        """
        let modifiedContent = Rewriter(.init(useClass: false)).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testClassWithComputedProperty() throws {
        let source = """
        class MyTests: XCTestCase {
            var value: Int { 42 }
            func testExample() { _ = value }
        }
        """
        let expected = """
        class MyTests {
            var value: Int { 42 }
            @Test func testExample() { _ = value }
        }
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testStructAddsMutatingIfAccessesStoredProperty() throws {
        let source = """
        class MyTests: XCTestCase {
            var count = 0
            func testIncrement() { count += 1 }
        }
        """
        let expected = """
        struct MyTests {
            var count = 0
            @Test mutating func testIncrement() { count += 1 }
        }
        """
        let modifiedContent = Rewriter(.init(useClass: false)).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testStructDoesNotAddMutatingIfNoStoredPropertyAccess() throws {
        let source = """
        class MyTests: XCTestCase {
            var count = 0
            func testNoMutation() { print("hi") }
        }
        """
        let expected = """
        struct MyTests {
            var count = 0
            @Test func testNoMutation() { print("hi") }
        }
        """
        let modifiedContent = Rewriter(.init(useClass: false)).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testClassWithAttributes() throws {
        let source = """
        @available(iOS 13, *)
        class MyTests: XCTestCase {
            func testExample() {}
        }
        """
        let expected = """
        @available(iOS 13, *)
        class MyTests {
            @Test func testExample() {}
        }
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testClassWithTrailingTrivia() throws {
        let source = """
        class MyTests: XCTestCase { // trailing comment
            func testExample() {}
        }
        """
        let expected = """
        class MyTests { // trailing comment
            @Test func testExample() {}
        }
        """
        let modifiedContent = Rewriter().rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

    @Test func testComplexSetupWithSuperCall() throws {
        let source = """
        class MyTests: XCTestCase {
            var testValue: Int = 0

            override func setUp() {
                super.setUp()
                testValue = 42
                configureEnvironment()
            }

            private func configureEnvironment() {
                // Configuration code
            }

            func testMyTest() {
                // Test code
            }
        }
        """
        let expected = """
        struct MyTests {
            var testValue: Int = 0

            init() {
                testValue = 42
                configureEnvironment()
            }

            private func configureEnvironment() {
                // Configuration code
            }

            @Test func testMyTest() {
                // Test code
            }
        }
        """
        let modifiedContent = Rewriter(.init(useClass: false)).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }

        @Test func testComplexClassSetupWithSuperCall() throws {
        let source = """
        class MyTests: XCTestCase {
            var testValue: Int = 0

            override func setUp() {
                super.setUp()
                testValue = 42
                configureEnvironment()
            }

            private func configureEnvironment() {
                // Configuration code
            }

            func testMyTest() {
                // Test code
            }
        }
        """
        let expected = """
        class MyTests {
            var testValue: Int = 0

            init() {
                testValue = 42
                configureEnvironment()
            }

            private func configureEnvironment() {
                // Configuration code
            }

            @Test func testMyTest() {
                // Test code
            }
        }
        """
        let modifiedContent = Rewriter(.init(useClass: true)).rewrite(source: source)
        expectStringDiff(modifiedContent, expected)
    }
}
