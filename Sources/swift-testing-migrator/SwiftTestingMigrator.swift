import ArgumentParser
import Foundation
import SwiftParser
import SwiftSyntax
import TestingMigrator

@main
struct SwiftTestingMigrator: AsyncParsableCommand {
    mutating func run() async throws {
        let source = """
        import Foundation
        import XCTest
        
        final class _ArrayExtensionsTests: XCTestCase {
            func testSubscriptGet() {
                let numbers = [0, 1]
                
                XCTAssertEqual(numbers[0], 0)
                XCTAssertNotEqual(numbers[1], 2)
                XCTAssertNotEqual(numbers[1], 2, "Must be different")
                XCTAssertNotEqual(numbers[1], 2, "Must be different", file: #file, line: #line)
                XCTAssertNotEqual(numbers[1], 2, line: #line)
                
                let n = NSString()
                let n1 = n
                let n2 = NSString("1")
                XCTAssertIdentical(n, n1)
                XCTAssertNotIdentical(n, n2)
                
                XCTAssertGreaterThan(numbers[1], 0)
                XCTAssertGreaterThanOrEqual(numbers[1], 0)
                XCTAssertLessThanOrEqual(numbers[0], 1)
                XCTAssertLessThan(numbers[0], 1)
                
                XCTAssert(numbers[1] == 1)
                XCTAssertTrue(numbers[0] == 0)
                XCTAssertFalse(numbers[0] == 2)
                XCTAssertFalse(false)
        
                XCTAssertNil(
                    nil,
                    "Must be nil"
                )
                XCTAssertNotNil(1)
                XCTFail("Test")
        
                let x = try XCTUnwrap(.some(1))
            }
            
            func testSubscriptSet() async throws {
                var numbers = [0, 1]
                
                numbers[0] = 12
                numbers[1] = 13
                
                XCTAssertEqual(numbers, [12, 13])
            }
        }
        """
        let modifiedSourceFile = Rewriter().rewrite(source: source)
        
        print(modifiedSourceFile)
    }
}
