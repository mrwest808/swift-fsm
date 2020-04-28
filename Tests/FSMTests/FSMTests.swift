import XCTest
@testable import FSM

final class FSMTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(FSM().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
