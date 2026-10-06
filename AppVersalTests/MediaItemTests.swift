import XCTest
import Photos
@testable import AppVersal

final class MediaItemTests: XCTestCase {

    func testFormattedDurationForVideo() {
        let asset = PHAsset()
        let item = MediaItem(asset: asset)
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

    func testSimilarGroupReclaimableSpaceAndBestItem() {
        let asset1 = PHAsset()
        let asset2 = PHAsset()
        let item1 = MediaItem(asset: asset1, fileSize: 4_000_000)
        let item2 = MediaItem(asset: asset2, fileSize: 6_000_000)

        let group = SimilarGroup(items: [item1, item2], similarityScore: 0.95)
        XCTAssertEqual(group.bestItem?.id, item2.id)
        XCTAssertEqual(group.removableItems.count, 1)
        XCTAssertEqual(group.removableItems.first?.id, item1.id)
        XCTAssertEqual(group.reclaimableSpace, 4_000_000)
        XCTAssertEqual(group.formattedScore, "95% match")
    }

    func testMediaItemProperties() {
        let asset = PHAsset()
        let item = MediaItem(asset: asset, fileSize: 3_500_000)
        XCTAssertEqual(item.formattedSize, ByteFormatter.format(3_500_000))
    }
}
