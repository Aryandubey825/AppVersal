import Foundation
import Photos
import OSLog

@GalleryAnalysisActor
public final class SimilarPhotoAnalyzer {

    public struct ProgressUpdate: Sendable {
        public let processed: Int
        public let total: Int
        public let currentGroups: [SimilarGroup]
    }

    /// Finds photos that look nearly the same (e.g., burst shots, same scene), matching GalleryCleaner logic
    public static func findSimilarPhotos(from items: [MediaItem]) -> [SimilarGroup] {
        let photoItems = items.filter { $0.isPhoto }
        let candidateItems = photoItems.isEmpty ? items.filter { $0.mediaType == .image } : photoItems
        guard candidateItems.count > 1 else { return [] }

        // Sort items chronologically
        let sorted = candidateItems.sorted {
            ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast)
        }

        var clusters: [[MediaItem]] = []
        var currentCluster: [MediaItem] = [sorted[0]]

        for i in 1..<sorted.count {
            let prev = sorted[i - 1]
            let curr = sorted[i]

            let prevDate = prev.creationDate ?? .distantPast
            let currDate = curr.creationDate ?? .distantPast
            let timeDelta = abs(currDate.timeIntervalSince(prevDate))

            // Aspect ratio calculation
            let prevAspect = Double(prev.pixelWidth) / Double(max(1, prev.pixelHeight))
            let currAspect = Double(curr.pixelWidth) / Double(max(1, curr.pixelHeight))
            let aspectDiff = abs(prevAspect - currAspect)
            let invertedAspectDiff = abs((1.0 / prevAspect) - currAspect)
            let isSimilarAspect = aspectDiff < 0.15 || invertedAspectDiff < 0.15

            // Total cluster duration so far (prevents clusters spanning too many hours)
            let clusterStartDate = currentCluster.first?.creationDate ?? .distantPast
            let clusterSpan = abs(currDate.timeIntervalSince(clusterStartDate))

            // Conditions matching GalleryCleaner:
            // 1. Photos taken within 90 seconds with similar aspect ratio
            // 2. Or burst shots taken within 10 seconds
            // 3. Keep cluster span reasonable (<= 10 minutes)
            let isBurst = timeDelta <= 10.0
            let isSameScene = timeDelta <= 90.0 && isSimilarAspect
            let canAddToCluster = (isBurst || isSameScene) && (clusterSpan <= 600.0)

            if canAddToCluster {
                currentCluster.append(curr)
            } else {
                if currentCluster.count > 1 {
                    clusters.append(currentCluster)
                }
                currentCluster = [curr]
            }
        }

        if currentCluster.count > 1 {
            clusters.append(currentCluster)
        }

        var groups: [SimilarGroup] = []
        for cluster in clusters {
            // Best item is the one with highest resolution / file size
            let best = cluster.max {
                let s0 = $0.fileSize ?? 0
                let s1 = $1.fileSize ?? 0
                if s0 != s1 { return s0 < s1 }
                return ($0.pixelWidth * $0.pixelHeight) < ($1.pixelWidth * $1.pixelHeight)
            } ?? cluster[0]

            let others = cluster.filter { $0.id != best.id }

            // Similarity score based on time delta: burst photos (0-5s) ~ 98%, 30s ~ 92%, 90s ~ 85%
            let deltas = zip(cluster, cluster.dropFirst()).map {
                abs(($0.1.creationDate ?? .distantPast).timeIntervalSince($0.0.creationDate ?? .distantPast))
            }
            let avgDelta = deltas.isEmpty ? 0.0 : deltas.reduce(0, +) / Double(deltas.count)
            let score = max(0.80, min(0.98, 0.98 - Float(avgDelta / 90.0) * 0.12))

            let group = SimilarGroup(
                primaryItem: best,
                similarItems: others,
                averageSimilarityScore: score,
                selectedKeepId: best.id
            )
            groups.append(group)
        }

        // Sort groups by reclaimable space descending (biggest savings first, matching GalleryCleaner)
        return groups.sorted { $0.reclaimableSpace > $1.reclaimableSpace }
    }

    public static func analyze(items: [MediaItem]) -> AsyncStream<ProgressUpdate> {
        AsyncStream { continuation in
            let task = Task {
                let total = items.count
                guard total > 1 else {
                    continuation.yield(ProgressUpdate(processed: total, total: total, currentGroups: []))
                    continuation.finish()
                    return
                }

                // Yield initial starting state
                continuation.yield(ProgressUpdate(processed: 0, total: total, currentGroups: []))

                let groups = findSimilarPhotos(from: items)

                if Task.isCancelled {
                    continuation.finish()
                    return
                }

                // Yield completed state with groups
                continuation.yield(ProgressUpdate(processed: total, total: total, currentGroups: groups))
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    public static func quickScan(items: [MediaItem]) -> (count: Int, previewAsset: PHAsset?) {
        let groups = findSimilarPhotos(from: items)
        let totalCount = groups.reduce(0) { $0 + $1.allItems.count }
        let preview = groups.first?.primaryItem.asset
        return (totalCount, preview)
    }

    public static func quickSimilarCount(items: [MediaItem]) -> Int {
        quickScan(items: items).count
    }
}
