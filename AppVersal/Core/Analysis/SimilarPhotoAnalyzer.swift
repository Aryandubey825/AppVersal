import Foundation
import Photos
import Vision
import UIKit
import OSLog

@GalleryAnalysisActor
public final class SimilarPhotoAnalyzer {

    public struct ProgressUpdate: Sendable {
        public let processed: Int
        public let total: Int
        public let currentGroups: [SimilarGroup]
    }

    public static let similarityThreshold: Float = 0.48
    public static let closeTimeSimilarityThreshold: Float = 0.50
    public static let defaultSimilarityThreshold: Float = 0.44
    public static let maxTimeIntervalBetweenShots: TimeInterval = 48 * 3600

    public static func analyze(items: [MediaItem]) -> AsyncStream<ProgressUpdate> {
        AsyncStream { continuation in
            let task = Task {
                let total = items.count
                guard total > 0 else {
                    continuation.yield(ProgressUpdate(processed: 0, total: 0, currentGroups: []))
                    continuation.finish()
                    return
                }

                let sortedItems = items.sorted {
                    ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast)
                }

                var prints: [(item: MediaItem, print: VNFeaturePrintObservation)] = []
                var processedCount = 0

                for item in sortedItems {
                    if Task.isCancelled { break }
                    processedCount += 1

                    if let featurePrint = extractFeaturePrint(for: item.asset) {
                        prints.append((item, featurePrint))
                    }

                    if processedCount % 5 == 0 && processedCount < total {
                        continuation.yield(ProgressUpdate(processed: processedCount, total: total, currentGroups: []))
                    }
                }

                if Task.isCancelled {
                    continuation.finish()
                    return
                }

                var visited = Set<String>()
                var similarGroups: [SimilarGroup] = []

                for i in 0..<prints.count {
                    if Task.isCancelled { break }
                    let primary = prints[i]
                    if visited.contains(primary.item.id) { continue }

                    var matches: [MediaItem] = []
                    var distances: [Float] = []

                    for j in (i + 1)..<prints.count {
                        let candidate = prints[j]
                        if visited.contains(candidate.item.id) { continue }

                        let timeDiff: TimeInterval?
                        if let d1 = primary.item.creationDate, let d2 = candidate.item.creationDate {
                            timeDiff = abs(d1.timeIntervalSince(d2))
                        } else {
                            timeDiff = nil
                        }

                        if let diff = timeDiff, diff > maxTimeIntervalBetweenShots {
                            break
                        }

                        if timeDiff == nil && (j - i) > 25 {
                            break
                        }

                        let threshold: Float
                        if let diff = timeDiff, diff <= 1800 {
                            threshold = closeTimeSimilarityThreshold
                        } else {
                            threshold = defaultSimilarityThreshold
                        }

                        var distance: Float = 0
                        do {
                            try primary.print.computeDistance(&distance, to: candidate.print)
                            if distance <= threshold {
                                matches.append(candidate.item)
                                distances.append(distance)
                                visited.insert(candidate.item.id)
                            }
                        } catch {
                            continue
                        }
                    }

                    if !matches.isEmpty {
                        visited.insert(primary.item.id)
                        let avgDistance = distances.reduce(0, +) / Float(distances.count)
                        let score = max(0.5, min(0.99, 1.0 - (avgDistance * 0.85)))
                        let group = SimilarGroup(primaryItem: primary.item, similarItems: matches, averageSimilarityScore: score)
                        similarGroups.append(group)
                    }
                }

                similarGroups.sort {
                    ($0.primaryItem.creationDate ?? .distantPast) > ($1.primaryItem.creationDate ?? .distantPast)
                }

                continuation.yield(ProgressUpdate(processed: total, total: total, currentGroups: similarGroups))
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    public static func quickScan(items: [MediaItem]) -> (count: Int, previewAsset: PHAsset?) {
        guard items.count > 1 else { return (0, nil) }

        let sortedItems = items.sorted {
            ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast)
        }

        var prints: [(item: MediaItem, print: VNFeaturePrintObservation)] = []

        for item in sortedItems.prefix(120) {
            if let print = extractFeaturePrint(for: item.asset) {
                prints.append((item, print))
            }
        }

        var matchedIds = Set<String>()
        var preview: PHAsset? = nil

        for i in 0..<prints.count {
            let primary = prints[i]
            for j in (i + 1)..<prints.count {
                let candidate = prints[j]
                if matchedIds.contains(candidate.item.id) { continue }

                let timeDiff: TimeInterval?
                if let d1 = primary.item.creationDate, let d2 = candidate.item.creationDate {
                    timeDiff = abs(d1.timeIntervalSince(d2))
                } else {
                    timeDiff = nil
                }

                if let diff = timeDiff, diff > maxTimeIntervalBetweenShots {
                    break
                }

                if timeDiff == nil && (j - i) > 25 {
                    break
                }

                let threshold: Float
                if let diff = timeDiff, diff <= 1800 {
                    threshold = closeTimeSimilarityThreshold
                } else {
                    threshold = defaultSimilarityThreshold
                }

                var distance: Float = 0
                if (try? primary.print.computeDistance(&distance, to: candidate.print)) != nil {
                    if distance <= threshold {
                        matchedIds.insert(primary.item.id)
                        matchedIds.insert(candidate.item.id)
                        if preview == nil {
                            preview = primary.item.asset
                        }
                    }
                }
            }
        }
        return (matchedIds.count, preview)
    }

    public static func quickSimilarCount(items: [MediaItem]) -> Int {
        quickScan(items: items).count
    }

    private static func extractFeaturePrint(for asset: PHAsset) -> VNFeaturePrintObservation? {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true

        var resultObservation: VNFeaturePrintObservation? = nil
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 256, height: 256),
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            guard let cgImage = image?.cgImage else { return }

            let request = VNGenerateImageFeaturePrintRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
                resultObservation = request.results?.first as? VNFeaturePrintObservation
            } catch {
                resultObservation = nil
            }
        }
        return resultObservation
    }
}
