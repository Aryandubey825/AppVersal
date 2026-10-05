//
//  SimilarVideoAnalyzer.swift
//  AppVersal
//

import Foundation
import Photos
import OSLog

@GalleryAnalysisActor
public final class SimilarVideoAnalyzer {

    public struct ProgressUpdate: Sendable {
        public let processed: Int
        public let total: Int
        public let currentGroups: [SimilarGroup]
    }

    public static func analyze(items: [MediaItem]) -> AsyncStream<ProgressUpdate> {
        AsyncStream { continuation in
            let task = Task {
                let videoItems = items.filter { $0.isVideo }
                let total = videoItems.count
                guard total > 1 else {
                    continuation.yield(ProgressUpdate(processed: total, total: total, currentGroups: []))
                    continuation.finish()
                    return
                }

                // Sort by creation date descending
                let sortedVideos = videoItems.sorted {
                    ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast)
                }

                var visited = Set<String>()
                var groups: [SimilarGroup] = []
                var processedCount = 0

                for i in 0..<sortedVideos.count {
                    if Task.isCancelled { break }
                    processedCount += 1

                    let primary = sortedVideos[i]
                    if visited.contains(primary.id) {
                        if processedCount % 5 == 0 || processedCount == total {
                            continuation.yield(ProgressUpdate(processed: processedCount, total: total, currentGroups: groups))
                        }
                        continue
                    }

                    var matches: [MediaItem] = []
                    var scores: [Float] = []

                    for j in (i + 1)..<sortedVideos.count {
                        let candidate = sortedVideos[j]
                        if visited.contains(candidate.id) { continue }

                        if let score = evaluateVideoSimilarity(primary: primary, candidate: candidate) {
                            matches.append(candidate)
                            scores.append(score)
                            visited.insert(candidate.id)
                        }
                    }

                    if !matches.isEmpty {
                        visited.insert(primary.id)
                        let avgScore = scores.reduce(0, +) / Float(scores.count)
                        let group = SimilarGroup(
                            primaryItem: primary,
                            similarItems: matches,
                            averageSimilarityScore: avgScore
                        )
                        groups.append(group)
                    }

                    if processedCount % 5 == 0 || processedCount == total {
                        continuation.yield(ProgressUpdate(processed: processedCount, total: total, currentGroups: groups))
                    }
                }

                continuation.yield(ProgressUpdate(processed: total, total: total, currentGroups: groups))
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Fast scan returning total similar video count and preview asset for cards
    public static func quickScan(items: [MediaItem]) -> (count: Int, previewAsset: PHAsset?) {
        let videoItems = items.filter { $0.isVideo }
        guard videoItems.count > 1 else { return (0, nil) }

        let sortedVideos = videoItems.sorted {
            ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast)
        }

        var visited = Set<String>()
        var totalSimilarCount = 0
        var previewAsset: PHAsset? = nil

        for i in 0..<sortedVideos.count {
            let primary = sortedVideos[i]
            if visited.contains(primary.id) { continue }

            var matchesCount = 0

            // Check against nearby items in date order
            let maxLookahead = min(sortedVideos.count, i + 25)
            for j in (i + 1)..<maxLookahead {
                let candidate = sortedVideos[j]
                if visited.contains(candidate.id) { continue }

                if evaluateVideoSimilarity(primary: primary, candidate: candidate) != nil {
                    matchesCount += 1
                    visited.insert(candidate.id)
                }
            }

            if matchesCount > 0 {
                visited.insert(primary.id)
                totalSimilarCount += (matchesCount + 1)
                if previewAsset == nil {
                    previewAsset = primary.asset
                }
            }
        }

        return (totalSimilarCount, previewAsset)
    }

    public static func quickSimilarCount(items: [MediaItem]) -> Int {
        quickScan(items: items).count
    }

    /// Evaluates if two videos represent similar takes, burst clips, or visually related recordings
    private static func evaluateVideoSimilarity(primary: MediaItem, candidate: MediaItem) -> Float? {
        let sameDimensions = (primary.pixelWidth == candidate.pixelWidth && primary.pixelHeight == candidate.pixelHeight) ||
                             (primary.pixelWidth == candidate.pixelHeight && primary.pixelHeight == candidate.pixelWidth)

        guard sameDimensions else { return nil }

        let durationDiff = abs(primary.duration - candidate.duration)
        guard durationDiff <= 3.5 else { return nil }

        // Check capture time proximity if available
        let hasCloseDates: Bool
        let timeScore: Double
        if let d1 = primary.creationDate, let d2 = candidate.creationDate {
            let timeDiff = abs(d1.timeIntervalSince(d2))
            // Videos within 15 minutes of each other (e.g. multiple takes or scene shots)
            if timeDiff <= 900 {
                hasCloseDates = true
                timeScore = max(0.6, 1.0 - (timeDiff / 1800.0))
            } else if durationDiff <= 1.0 {
                // If duration is extremely close (<= 1.0s), allow up to 2 hours
                hasCloseDates = timeDiff <= 7200
                timeScore = max(0.5, 1.0 - (timeDiff / 7200.0))
            } else {
                hasCloseDates = false
                timeScore = 0.5
            }
        } else {
            // Missing creation dates - rely on strict duration match
            hasCloseDates = durationDiff <= 1.5
            timeScore = 0.7
        }

        guard hasCloseDates else { return nil }

        let durationScore = max(0.5, 1.0 - (durationDiff / 4.0))
        let combinedScore = Float((durationScore * 0.6) + (timeScore * 0.4))
        return min(0.98, max(0.65, combinedScore))
    }
}
