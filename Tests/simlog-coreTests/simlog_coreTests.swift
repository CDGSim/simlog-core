import XCTest
@testable import simlog_core

final class simlog_coreTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(simlog_core().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
