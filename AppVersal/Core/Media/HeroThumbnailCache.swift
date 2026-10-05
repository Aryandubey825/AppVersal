import UIKit
import Photos
import Combine

@MainActor
public final class HeroThumbnailCache {
    public static let shared = HeroThumbnailCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 100 * 1024 * 1024
    }

    public func image(for localIdentifier: String) -> UIImage? {
        cache.object(forKey: localIdentifier as NSString)
    }

    public func setImage(_ image: UIImage, for localIdentifier: String) {
        cache.setObject(image, forKey: localIdentifier as NSString)
    }

    public func removeImage(for localIdentifier: String) {
        cache.removeObject(forKey: localIdentifier as NSString)
    }

    public func loadThumbnail(for asset: PHAsset, targetSize: CGSize = CGSize(width: 600, height: 400)) async -> UIImage? {
        let key = asset.localIdentifier as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true

        return await withCheckedContinuation { continuation in
            var hasResumed = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { [weak self] image, info in
                if let img = image {
                    self?.cache.setObject(img, forKey: key)
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(returning: img)
                    }
                } else {
                    let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                    if !isDegraded && !hasResumed {
                        hasResumed = true
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }
}
