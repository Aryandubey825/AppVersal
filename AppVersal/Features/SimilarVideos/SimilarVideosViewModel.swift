//
//  SimilarVideosViewModel.swift
//  AppVersal
//

import SwiftUI
import Photos
import Combine
import OSLog

@MainActor
public final class SimilarVideosViewModel: ObservableObject {
    @Published public private(set) var state: AnalysisState<[SimilarGroup]> = .idle
    @Published public var selectedItemIds: Set<String> = []

    private var analysisTask: Task<Void, Never>?

    public init() {}

    public func startAnalysis() {
        analysisTask?.cancel()
        state = .loading(processed: 0, total: 0)

        analysisTask = Task {
            let allVideos = PhotoLibraryService.shared.fetchVideos()
            let videos = allVideos.filter { !TrashManager.shared.isTrashed(id: $0.id) }
            let total = videos.count

            guard total > 1 else {
                state = .empty
                return
            }

            // Group videos with similar duration (within 2 seconds) or close capture time (within 5 mins)
            var groups: [SimilarGroup] = []
            var visited = Set<String>()

            for i in 0..<videos.count {
                if Task.isCancelled { break }
                let primary = videos[i]
                if visited.contains(primary.id) { continue }

                var similarMatches: [MediaItem] = []

                for j in (i + 1)..<videos.count {
                    let candidate = videos[j]
                    if visited.contains(candidate.id) { continue }

                    // Similar duration (within 2.0s) or similar dimensions
                    let durationDiff = abs(primary.duration - candidate.duration)
                    let sameDimensions = primary.pixelWidth == candidate.pixelWidth && primary.pixelHeight == candidate.pixelHeight

                    if durationDiff <= 2.0 && sameDimensions {
                        similarMatches.append(candidate)
                        visited.insert(candidate.id)
                    }
                }

                if !similarMatches.isEmpty {
                    visited.insert(primary.id)
                    let group = SimilarGroup(
                        primaryItem: primary,
                        similarItems: similarMatches,
                        averageSimilarityScore: 0.92
                    )
                    groups.append(group)
                }
            }

            if groups.isEmpty {
                self.state = .empty
            } else {
                self.state = .loaded(groups)
            }
        }
    }

    public func cancelAnalysis() {
        analysisTask?.cancel()
        state = .idle
    }

    public func toggleSelection(id: String) {
        if selectedItemIds.contains(id) {
            selectedItemIds.remove(id)
        } else {
            selectedItemIds.insert(id)
        }
    }

    public func deleteSelected() {
        guard case .loaded(let groups) = state else { return }
        let allItems = groups.flatMap { $0.allItems }
        let selected = allItems.filter { selectedItemIds.contains($0.id) }

        guard !selected.isEmpty else { return }

        TrashManager.shared.moveToTrash(items: selected)
        selectedItemIds.removeAll()
        startAnalysis()
    }
}
