import SwiftUI
import Photos
import Combine
import OSLog

@MainActor
public final class SimilarPhotosViewModel: ObservableObject {
    @Published public private(set) var state: AnalysisState<[SimilarGroup]> = .idle
    @Published public var selectedItemIds: Set<String> = []
    @Published public var selectedDateFilter: DateFilterOption = .all

    public var filteredGroups: [SimilarGroup] {
        guard case .loaded(let groups) = state else { return [] }
        guard selectedDateFilter.isFiltered else { return groups }
        return groups.compactMap { group in
            let matching = group.allItems.filter { selectedDateFilter.matches(date: $0.creationDate) }
            guard matching.count >= 2 else { return nil }
            return SimilarGroup(
                id: group.id,
                primaryItem: matching[0],
                similarItems: Array(matching.dropFirst()),
                averageSimilarityScore: group.averageSimilarityScore
            )
        }
    }

    private var analysisTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    public init() {
        setupObservers()
    }

    private func setupObservers() {
        PhotoLibraryService.shared.libraryUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                switch self.state {
                case .loaded, .empty:
                    self.startAnalysis()
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    public func startAnalysis() {
        analysisTask?.cancel()
        state = .loading(processed: 0, total: 0)

        analysisTask = Task {
            let allPhotos = PhotoLibraryService.shared.fetchAllPhotos()
            let photos = allPhotos.filter { !TrashManager.shared.isTrashed(id: $0.id) }
            let total = photos.count

            guard total > 0 else {
                state = .empty
                return
            }

            for await update in await SimilarPhotoAnalyzer.analyze(items: photos) {
                if Task.isCancelled { break }

                if update.processed < update.total {
                    self.state = .loading(processed: update.processed, total: update.total)
                } else {
                    if update.currentGroups.isEmpty {
                        self.state = .empty
                    } else {
                        self.state = .loaded(update.currentGroups)
                    }
                }
            }

            if case .loading = self.state {
                self.state = .empty
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
        let deletedIds = selectedItemIds

        let updatedGroups = groups.compactMap { group -> SimilarGroup? in
            let remaining = group.allItems.filter { !deletedIds.contains($0.id) }
            guard remaining.count >= 2 else { return nil }
            return SimilarGroup(
                id: group.id,
                primaryItem: remaining[0],
                similarItems: Array(remaining.dropFirst()),
                averageSimilarityScore: group.averageSimilarityScore
            )
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedItemIds.removeAll()
            if updatedGroups.isEmpty {
                state = .empty
            } else {
                state = .loaded(updatedGroups)
            }
        }
    }
}
