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
                items: matching,
                similarityScore: Double(group.averageSimilarityScore),
                selectedKeepId: group.selectedKeepId
            )
        }
    }

    public var totalReclaimableSpace: Int64 {
        filteredGroups.reduce(0) { $0 + $1.reclaimableSpace }
    }

    public var formattedTotalReclaimableSpace: String {
        ByteFormatter.format(totalReclaimableSpace)
    }

    public var selectedReclaimableSpace: Int64 {
        let allItems = filteredGroups.flatMap { $0.allItems }
        return allItems
            .filter { selectedItemIds.contains($0.id) }
            .compactMap { $0.fileSize }
            .reduce(0, +)
    }

    public var formattedSelectedReclaimableSpace: String {
        ByteFormatter.format(selectedReclaimableSpace)
    }

    public var allInferiorSelected: Bool {
        let inferiors = filteredGroups.flatMap { $0.removableItems }.map { $0.id }
        return !inferiors.isEmpty && inferiors.allSatisfy { selectedItemIds.contains($0) }
    }

    public func autoSelectInferior() {
        let inferiors = filteredGroups.flatMap { $0.removableItems }.map { $0.id }
        selectedItemIds = Set(inferiors)
    }

    public func toggleAutoSelect() {
        if allInferiorSelected {
            selectedItemIds.removeAll()
        } else {
            autoSelectInferior()
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
                        self.autoSelectInferior()
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
                items: remaining,
                similarityScore: Double(group.averageSimilarityScore),
                selectedKeepId: group.selectedKeepId
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
