import XCTest
@testable import SteamcLog

final class SteamcLogTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SteamcLog().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
