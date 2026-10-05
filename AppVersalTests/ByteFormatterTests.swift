import XCTest
@testable import AppVersal

final class ByteFormatterTests: XCTestCase {

    func testZeroBytesFormatting() {
        let result = ByteFormatter.format(0)
        XCTAssertEqual(result, "0 B")
    }

    func testKilobytesFormatting() {
        let result = ByteFormatter.format(1024)
        XCTAssertTrue(result.contains("KB") || result.contains("kB") || result.contains("1 KB"))
    }

    func testMegabytesFormatting() {
        let result = ByteFormatter.format(1048576 * 5)
        XCTAssertTrue(result.contains("MB"))
    }

    func testGigabytesFormatting() {
        let result = ByteFormatter.format(1073741824 * 2)
        XCTAssertTrue(result.contains("GB"))
    }
}
