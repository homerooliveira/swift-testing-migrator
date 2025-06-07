import Foundation
import XCTest

final class ArrayExtensionsTests: XCTestCase {
    func testSubscriptGet() {
        XCTAssertThrowsError(try f()) { error in
            XCTAssertEqual(error.localizedDescription, "bla")
            let number: Int? = 1
            XCTAssertNotNil(number)
        }

        XCTAssertEqual(1, 1)
    }

    func f() throws {
        throw CocoaError(.executableLoad)
    }
}
