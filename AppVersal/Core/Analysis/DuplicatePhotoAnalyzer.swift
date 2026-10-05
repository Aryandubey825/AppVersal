//
//  DuplicatePhotoAnalyzer.swift
//  AppVersal
//

import Foundation
import Photos
import CryptoKit
import UIKit
import OSLog

@GalleryAnalysisActor
public final class DuplicatePhotoAnalyzer {

    public struct ProgressUpdate: Sendable {
        public let processed: Int
        public let total: Int
        public let currentGroups: [DuplicateGroup]
    }

    public static func analyze(items: [MediaItem]) -> AsyncStream<ProgressUpdate> {
        AsyncStream { continuation in
            let task = Task {
                let total = items.count
                guard total > 0 else {
                    continuation.yield(ProgressUpdate(processed: 0, total: 0, currentGroups: []))
                    continuation.finish()
                    return
                }

                // Step 1: Pre-filter by dimensions (pixelWidth, pixelHeight)
                var dimensionBuckets: [String: [MediaItem]] = [:]
                for item in items {
                    let dimKey = "\(item.pixelWidth)x\(item.pixelHeight)"
                    dimensionBuckets[dimKey, default: []].append(item)
                }

                var fingerprintMap: [String: [MediaItem]] = [:]
                var processedCount = 0

                for item in items {
                    if Task.isCancelled { break }
                    processedCount += 1

                    let dimKey = "\(item.pixelWidth)x\(item.pixelHeight)"
                    let candidates = dimensionBuckets[dimKey] ?? []

                    // If at least two photos have matching dimensions, compare content hash
                    if candidates.count > 1 {
                        if let hash = computeContentFingerprint(for: item.asset) {
                            let groupKey = "\(dimKey)_\(hash)"
                            fingerprintMap[groupKey, default: []].append(item)
                        }
                    }

                    if processedCount % 5 == 0 || processedCount == total {
                        let activeGroups = sortedDuplicateGroups(from: fingerprintMap)
                        continuation.yield(ProgressUpdate(processed: processedCount, total: total, currentGroups: activeGroups))
                    }
                }

                let finalGroups = sortedDuplicateGroups(from: fingerprintMap)
                continuation.yield(ProgressUpdate(processed: total, total: total, currentGroups: finalGroups))
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Fast synchronous scan returning duplicate count and the first duplicate asset for card preview
    public static func quickScan(items: [MediaItem]) -> (count: Int, previewAsset: PHAsset?) {
        guard items.count > 1 else { return (0, nil) }

        var dimensionBuckets: [String: [MediaItem]] = [:]
        for item in items {
            let dimKey = "\(item.pixelWidth)x\(item.pixelHeight)"
            dimensionBuckets[dimKey, default: []].append(item)
        }

        let candidates = dimensionBuckets.values.filter { $0.count > 1 }.flatMap { $0 }
        guard candidates.count > 1 else { return (0, nil) }

        var fingerprintMap: [String: [MediaItem]] = [:]
        for item in candidates {
            let dimKey = "\(item.pixelWidth)x\(item.pixelHeight)"
            if let hash = computeContentFingerprint(for: item.asset) {
                let groupKey = "\(dimKey)_\(hash)"
                fingerprintMap[groupKey, default: []].append(item)
            }
        }

        let sortedGroups = sortedDuplicateGroups(from: fingerprintMap)
        let totalCount = sortedGroups.reduce(0) { $0 + $1.items.count }
        let preview = sortedGroups.first?.items.first?.asset
        return (totalCount, preview)
    }

    public static func quickDuplicateCount(items: [MediaItem]) -> Int {
        quickScan(items: items).count
    }

    /// Deterministic sorting of duplicate groups (newest photos first)
    private static func sortedDuplicateGroups(from fingerprintMap: [String: [MediaItem]]) -> [DuplicateGroup] {
        fingerprintMap.values
            .filter { $0.count > 1 }
            .map { group in
                group.sorted { ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast) }
            }
            .sorted { group1, group2 in
                let date1 = group1.first?.creationDate ?? .distantPast
                let date2 = group2.first?.creationDate ?? .distantPast
                if date1 != date2 {
                    return date1 > date2
                }
                return (group1.first?.id ?? "") > (group2.first?.id ?? "")
            }
            .map { DuplicateGroup(fingerprint: $0.first?.id ?? "", items: $0) }
    }

    /// Synchronous 32x32 thumbnail pixel hash on background actor thread
    private static func computeContentFingerprint(for asset: PHAsset) -> String? {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true

        var resultHash: String? = nil
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 64, height: 64),
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            guard let img = image else { return }
            let renderSize = CGSize(width: 32, height: 32)
            let renderer = UIGraphicsImageRenderer(size: renderSize)
            let pngData = renderer.pngData { _ in
                img.draw(in: CGRect(origin: .zero, size: renderSize))
            }
            let digest = SHA256.hash(data: pngData)
            resultHash = digest.compactMap { String(format: "%02x", $0) }.joined()
        }
        return resultHash
    }
}
