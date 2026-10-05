//
//  DuplicateVideoAnalyzer.swift
//  AppVersal
//

import Foundation
import Photos
import CryptoKit
import OSLog

@GalleryAnalysisActor
public final class DuplicateVideoAnalyzer {

    public struct ProgressUpdate: Sendable {
        public let processed: Int
        public let total: Int
        public let currentGroups: [DuplicateGroup]
    }

    public static func analyze(items: [MediaItem]) -> AsyncStream<ProgressUpdate> {
        AsyncStream { continuation in
            let task = Task {
                let videoItems = items.filter { $0.isVideo }
                let total = videoItems.count
                guard total > 0 else {
                    continuation.yield(ProgressUpdate(processed: 0, total: 0, currentGroups: []))
                    continuation.finish()
                    return
                }

                // Step 1: Pre-filter by exact duration (ms precision) + fileSize
                var metadataBucket: [String: [MediaItem]] = [:]
                for item in videoItems {
                    let durationMs = Int((item.duration * 1000).rounded())
                    let size = item.fileSize ?? 0
                    let key = "v_\(size)_\(durationMs)"
                    metadataBucket[key, default: []].append(item)
                }

                var fingerprintMap: [String: [MediaItem]] = [:]
                var processedCount = 0

                for item in videoItems {
                    if Task.isCancelled { break }
                    processedCount += 1

                    let durationMs = Int((item.duration * 1000).rounded())
                    let size = item.fileSize ?? 0
                    let key = "v_\(size)_\(durationMs)"

                    if let candidates = metadataBucket[key], candidates.count > 1 {
                        let fingerprint = computeVideoFingerprint(for: item)
                        fingerprintMap[fingerprint, default: []].append(item)
                    }

                    if processedCount % 5 == 0 || processedCount == total {
                        let groups = sortedDuplicateGroups(from: fingerprintMap)
                        continuation.yield(ProgressUpdate(processed: processedCount, total: total, currentGroups: groups))
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

    public static func quickScan(items: [MediaItem]) -> (count: Int, previewAsset: PHAsset?) {
        let videoItems = items.filter { $0.isVideo }
        guard videoItems.count > 1 else { return (0, nil) }

        var metadataBucket: [String: [MediaItem]] = [:]
        for item in videoItems {
            let durationMs = Int((item.duration * 1000).rounded())
            let size = item.fileSize ?? 0
            let key = "v_\(size)_\(durationMs)"
            metadataBucket[key, default: []].append(item)
        }

        let candidates = metadataBucket.values.filter { $0.count > 1 }.flatMap { $0 }
        guard candidates.count > 1 else { return (0, nil) }

        var fingerprintMap: [String: [MediaItem]] = [:]
        for item in candidates {
            let fingerprint = computeVideoFingerprint(for: item)
            fingerprintMap[fingerprint, default: []].append(item)
        }

        let sortedGroups = sortedDuplicateGroups(from: fingerprintMap)
        let totalCount = sortedGroups.reduce(0) { $0 + $1.items.count }
        let preview = sortedGroups.first?.items.first?.asset
        return (totalCount, preview)
    }

    public static func quickDuplicateCount(items: [MediaItem]) -> Int {
        quickScan(items: items).count
    }

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

    private static func computeVideoFingerprint(for item: MediaItem) -> String {
        let durationMs = Int((item.duration * 1000).rounded())
        let size = item.fileSize ?? 0
        let rawKey = "vid_fp_\(size)_\(durationMs)_\(item.pixelWidth)_\(item.pixelHeight)"
        let digest = SHA256.hash(data: Data(rawKey.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
