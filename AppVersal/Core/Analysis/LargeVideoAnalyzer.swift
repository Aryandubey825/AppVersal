//
//  LargeVideoAnalyzer.swift
//  AppVersal
//

import Foundation
import Photos
import OSLog

@GalleryAnalysisActor
public final class LargeVideoAnalyzer {

    public struct ProgressUpdate: Sendable {
        public let processed: Int
        public let total: Int
        public let sortedVideos: [MediaItem]
    }

    public static func analyze(items: [MediaItem]) -> AsyncStream<ProgressUpdate> {
        AsyncStream { continuation in
            let task = Task {
                let videoItems = items.filter { $0.isVideo }
                let total = videoItems.count
                guard total > 0 else {
                    continuation.yield(ProgressUpdate(processed: 0, total: 0, sortedVideos: []))
                    continuation.finish()
                    return
                }

                var processedItems: [MediaItem] = []
                var processedCount = 0

                for item in videoItems {
                    if Task.isCancelled { break }
                    processedCount += 1

                    var updatedItem = item
                    if updatedItem.fileSize == nil {
                        updatedItem.fileSize = PhotoLibraryService.getFileSize(for: item.asset)
                    }
                    processedItems.append(updatedItem)

                    if processedCount % 10 == 0 || processedCount == total {
                        let sorted = processedItems.sorted { ($0.fileSize ?? 0) > ($1.fileSize ?? 0) }
                        continuation.yield(ProgressUpdate(processed: processedCount, total: total, sortedVideos: sorted))
                    }
                }

                let finalSorted = processedItems.sorted { ($0.fileSize ?? 0) > ($1.fileSize ?? 0) }
                continuation.yield(ProgressUpdate(processed: total, total: total, sortedVideos: finalSorted))
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
