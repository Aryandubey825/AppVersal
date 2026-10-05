//
//  SimilarPhotoAnalyzer.swift
//  AppVersal
//

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

    public static func analyze(items: [MediaItem]) -> AsyncStream<ProgressUpdate> {
        AsyncStream { continuation in
            let task = Task {
                let total = items.count
                guard total > 0 else {
                    continuation.yield(ProgressUpdate(processed: 0, total: 0, currentGroups: []))
                    continuation.finish()
                    return
                }

                var prints: [(item: MediaItem, print: VNFeaturePrintObservation)] = []
                var processedCount = 0

                // Step 1: Extract Vision Feature Prints for candidate photos
                for item in items {
                    if Task.isCancelled { break }
                    processedCount += 1

                    if let featurePrint = extractFeaturePrint(for: item.asset) {
                        prints.append((item, featurePrint))
                    }

                    if processedCount % 5 == 0 || processedCount == total {
                        continuation.yield(ProgressUpdate(processed: processedCount, total: total, currentGroups: []))
                    }
                }

                // Step 2: Compare pairs
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

                        var distance: Float = 0
                        do {
                            try primary.print.computeDistance(&distance, to: candidate.print)
                            // Distance <= 0.45 indicates high visual similarity in Vision framework
                            if distance <= 0.45 {
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
                        let score = max(0.0, 1.0 - avgDistance)
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

    /// Fast scan returning similar count and first matched asset for card preview
    public static func quickScan(items: [MediaItem]) -> (count: Int, previewAsset: PHAsset?) {
        guard items.count > 1 else { return (0, nil) }
        var prints: [(item: MediaItem, print: VNFeaturePrintObservation)] = []

        // Extract prints for candidate comparison
        for item in items.prefix(60) {
            if let print = extractFeaturePrint(for: item.asset) {
                prints.append((item, print))
            }
        }

        var matchedIds = Set<String>()
        var preview: PHAsset? = nil

        for i in 0..<prints.count {
            for j in (i + 1)..<prints.count {
                var distance: Float = 0
                if (try? prints[i].print.computeDistance(&distance, to: prints[j].print)) != nil {
                    if distance <= 0.45 {
                        matchedIds.insert(prints[i].item.id)
                        matchedIds.insert(prints[j].item.id)
                        if preview == nil {
                            preview = prints[i].item.asset
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
        options.deliveryMode = .highQualityFormat
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
