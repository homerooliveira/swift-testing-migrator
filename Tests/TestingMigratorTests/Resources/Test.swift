import Foundation
import Testing

@Suite
class _ArrayExtensionsTests {
    @Test func testSubscriptGet() throws {
        let numbers = [0, 1]

        #expect(numbers[0] == 0)
        #expect(numbers[1] != 2)
        #expect(numbers[1] != 2, "Must be different")
        #expect(numbers[1] != 2, "Must be different")
        #expect(numbers[1] != 2)

        let n = NSString()
        let n1 = n
        let n2 = NSString("1")
        #expect(n === n1)
        #expect(n !== n2)

        #expect(numbers[1] > 0)
        #expect(numbers[1] >= 0)
        #expect(numbers[0] <= 1)
        #expect(numbers[0] < 1)

        #expect(numbers[1] == 1)
        #expect(numbers[0] == 0)
        #expect(!(numbers[0] == 2))
        let flag = false
        #expect(!flag)

        #expect(
            nil == nil,
            "Must be nil"
        )

        let number: Int? = 1
        #expect(number != nil)

        let x = try #require(.some(1))
        #expect(x == 1)
    }

    @Test func testSubscriptSet() async throws {
        var numbers = [0, 1]

        numbers[0] = 12
        numbers[1] = 13

        #expect(numbers == [12, 13])
    }
}
