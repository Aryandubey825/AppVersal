//
//  PhotoLibraryService.swift
//  AppVersal
//

import Foundation
import Photos
import Combine
import OSLog

public final class PhotoLibraryService: NSObject, @unchecked Sendable, PHPhotoLibraryChangeObserver {
    public static let shared = PhotoLibraryService()

    private let library = PHPhotoLibrary.shared()
    public let changePublisher = PassthroughSubject<PHChange, Never>()

    override private init() {
        super.init()
        library.register(self)
    }

    deinit {
        library.unregisterChangeObserver(self)
    }

    // MARK: - Fetch Operations

    public nonisolated func fetchScreenshots() -> [MediaItem] {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        return convertFetchResult(fetchResult)
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

    public nonisolated func countCategory(_ category: MediaCategory) -> Int {
        let options = PHFetchOptions()
        switch category {
        case .screenshots:
            options.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)
            return PHAsset.fetchAssets(with: .image, options: options).count
        case .videos, .largeVideos:
            return PHAsset.fetchAssets(with: .video, options: options).count
        case .duplicateVideos, .similarVideos:
            return 0
        case .duplicatePhotos, .similarPhotos:
            return 0
        }
    }

    // MARK: - Resource File Size

    public nonisolated static func getFileSize(for asset: PHAsset) -> Int64? {
        let resources = PHAssetResource.assetResources(for: asset)
        guard let primaryResource = resources.first(where: { $0.type == .photo || $0.type == .video || $0.type == .fullSizePhoto || $0.type == .fullSizeVideo }) ?? resources.first else {
            return nil
        }
        if let sizeNumber = primaryResource.value(forKey: "fileSize") as? NSNumber {
            return sizeNumber.int64Value
        }
        return nil
    }

    // MARK: - Asset Deletion

    public nonisolated func deleteAssets(_ assets: [PHAsset]) async throws {
        try await library.performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }
        AppLogger.photos.info("Successfully deleted \(assets.count) assets")
    }

    // MARK: - Helpers

    private nonisolated func convertFetchResult(_ fetchResult: PHFetchResult<PHAsset>) -> [MediaItem] {
        var items: [MediaItem] = []
        items.reserveCapacity(fetchResult.count)
        fetchResult.enumerateObjects { asset, _, _ in
            items.append(MediaItem(asset: asset, fileSize: Self.getFileSize(for: asset)))
        }
        return items
    }

    // MARK: - PHPhotoLibraryChangeObserver

    public nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        changePublisher.send(changeInstance)
    }
}
