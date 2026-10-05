//
//  MediaItemTests.swift
//  AppVersalTests
//

import XCTest
import Photos
@testable import AppVersal

final class MediaItemTests: XCTestCase {

    func testFormattedDurationForVideo() {
        let asset = PHAsset()
        var item = MediaItem(asset: asset)
        // Verify formatted duration defaults safely
        XCTAssertEqual(item.formattedDuration, "")
    }

    func testDuplicateGroupReclaimableSize() {
        let asset1 = PHAsset()
        let asset2 = PHAsset()
        let item1 = MediaItem(asset: asset1, fileSize: 5_000_000)
        let item2 = MediaItem(asset: asset2, fileSize: 5_000_000)

        let group = DuplicateGroup(fingerprint: "test_fp", items: [item1, item2])
        XCTAssertEqual(group.totalSizeByte, 10_000_000)
        XCTAssertEqual(group.reclaimableSizeByte, 5_000_000)
    }
}
