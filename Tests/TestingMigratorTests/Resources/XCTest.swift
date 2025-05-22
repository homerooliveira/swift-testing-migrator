import Foundation
import XCTest

final class ArrayExtensionsTests: XCTestCase {
    func testSubscriptGet() throws {
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
        let flag = false
        XCTAssertFalse(flag)

        XCTAssertNil(
            nil,
            "Must be nil"
        )

        let number: Int? = 1
        XCTAssertNotNil(number)

        let x = try XCTUnwrap(.some(1))
        XCTAssertEqual(x, 1)
    }
    
    func testSubscriptSet() async throws {
        var numbers = [0, 1]
        
        numbers[0] = 12
        numbers[1] = 13
        
        XCTAssertEqual(numbers, [12, 13])
    }
}