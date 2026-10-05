import UIKit
import Photos
import Combine

@MainActor
public final class MediaThumbnailService: Sendable {
    public static let shared = MediaThumbnailService()

    private let imageManager = PHCachingImageManager()

    private init() {}

    public func requestImage(
        for asset: PHAsset,
        targetSize: CGSize = CGSize(width: 300, height: 300),
        contentMode: PHImageContentMode = .aspectFill
    ) async -> UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        return await withCheckedContinuation { continuation in
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options) { image, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded {
                    continuation.resume(returning: image)
                }
            }
        }
    }

    public func startCaching(assets: [PHAsset], targetSize: CGSize = CGSize(width: 300, height: 300)) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        imageManager.startCachingImages(for: assets, targetSize: targetSize, contentMode: .aspectFill, options: options)
    }

    public func stopCaching(assets: [PHAsset], targetSize: CGSize = CGSize(width: 300, height: 300)) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        imageManager.stopCachingImages(for: assets, targetSize: targetSize, contentMode: .aspectFill, options: options)
    }
}
