import Foundation
import Photos
import Combine
import OSLog
import UIKit

public final class PhotoLibraryService: NSObject, @unchecked Sendable, PHPhotoLibraryChangeObserver {
    public nonisolated static let shared = PhotoLibraryService()

    private let library = PHPhotoLibrary.shared()
    public nonisolated let changePublisher = PassthroughSubject<PHChange, Never>()
    public nonisolated let libraryUpdatePublisher = PassthroughSubject<Void, Never>()

    override private init() {
        super.init()
        library.register(self)
        setupLifecycleObservers()
    }

    deinit {
        library.unregisterChangeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.notifyLibraryChanged()
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.notifyLibraryChanged()
        }
    }

    public nonisolated func notifyLibraryChanged() {
        libraryUpdatePublisher.send()
    }

    public nonisolated static func isLikelyScreenshot(asset: PHAsset) -> Bool {
        if asset.mediaSubtypes.contains(.photoScreenshot) {
            return true
        }

        let w = asset.pixelWidth
        let h = asset.pixelHeight
        guard w > 0 && h > 0 else { return false }
        let longer = max(w, h)
        let shorter = min(w, h)

        let knownScreenDimensions: Set<[Int]> = [
            [2556, 1179], [2796, 1290], [2622, 1206], [2868, 1320],
            [2532, 1170], [2778, 1284], [2436, 1125], [2688, 1242],
            [1792, 828],  [2340, 1080], [1334, 750],  [1920, 1080],
            [2732, 2048], [2388, 1668], [2360, 1640], [2160, 1620],
            [2560, 1600], [2880, 1800], [3024, 1964]
        ]
        if knownScreenDimensions.contains([longer, shorter]) {
            return true
        }

        let resources = PHAssetResource.assetResources(for: asset)
        for res in resources {
            let filename = res.originalFilename.lowercased()
            if filename.contains("screenshot") ||
               filename.contains("screen shot") ||
               filename.contains("screen_shot") ||
               filename.contains("screen-shot") ||
               filename.contains("screengrab") ||
               filename.contains("simulator") ||
               filename.contains("capture") ||
               filename.contains("snip") {
                return true
            }

            let isPNG = res.uniformTypeIdentifier == "public.png" || filename.hasSuffix(".png")
            if isPNG {
                let ratio = Double(longer) / Double(shorter)
                if (ratio >= 2.14 && ratio <= 2.25) || (ratio >= 1.76 && ratio <= 1.80) || (ratio >= 2.08 && ratio <= 2.13) {
                    return true
                }
            }
        }

        let ratio = Double(longer) / Double(shorter)
        if ratio >= 2.14 && ratio <= 2.22 {
            return true
        }

        return false
    }

    public nonisolated func fetchScreenshots() -> [MediaItem] {
        var assetMap: [String: PHAsset] = [:]

        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumScreenshots, options: nil)
        smartAlbums.enumerateObjects { album, _, _ in
            let fetchResult = PHAsset.fetchAssets(in: album, options: nil)
            fetchResult.enumerateObjects { asset, _, _ in
                assetMap[asset.localIdentifier] = asset
            }
        }

        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)
        let subtypeResult = PHAsset.fetchAssets(with: .image, options: options)
        subtypeResult.enumerateObjects { asset, _, _ in
            assetMap[asset.localIdentifier] = asset
        }

        let allImageOptions = PHFetchOptions()
        allImageOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let allImagesResult = PHAsset.fetchAssets(with: .image, options: allImageOptions)
        allImagesResult.enumerateObjects { asset, _, _ in
            if assetMap[asset.localIdentifier] == nil {
                if Self.isLikelyScreenshot(asset: asset) {
                    assetMap[asset.localIdentifier] = asset
                }
            }
        }

        let sortedAssets = assetMap.values.sorted {
            ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast)
        }
        return sortedAssets.map { MediaItem(asset: $0, fileSize: Self.getFileSize(for: $0)) }
    }

    public nonisolated func fetchVideos() -> [MediaItem] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(with: .video, options: options)
        return convertFetchResult(fetchResult)
    }

    public nonisolated func fetchAllPhotos() -> [MediaItem] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        return convertFetchResult(fetchResult)
    }

    public nonisolated static func getFileSize(for asset: PHAsset) -> Int64? {
        let resources = PHAssetResource.assetResources(for: asset)
        for res in resources {
            if let sizeNumber = res.value(forKey: "fileSize") as? NSNumber, sizeNumber.int64Value > 0 {
                return sizeNumber.int64Value
            }
        }
        if asset.mediaType == .video && asset.duration > 0 {
            let estimatedBytes = Int64(asset.duration * 2_500_000)
            return max(500_000, estimatedBytes)
        }
        return nil
    }

    public nonisolated func deleteAssets(_ assets: [PHAsset]) async throws {
        try await library.performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }
        AppLogger.photos.info("Successfully deleted \(assets.count) assets")
    }

    private nonisolated func convertFetchResult(_ fetchResult: PHFetchResult<PHAsset>) -> [MediaItem] {
        var items: [MediaItem] = []
        items.reserveCapacity(fetchResult.count)
        fetchResult.enumerateObjects { asset, _, _ in
            items.append(MediaItem(asset: asset, fileSize: Self.getFileSize(for: asset)))
        }
        return items
    }

    public nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        changePublisher.send(changeInstance)
        libraryUpdatePublisher.send()
    }
}
