import SwiftUI
import Photos
import Combine
import OSLog

@MainActor
public final class DuplicateVideosViewModel: ObservableObject {
    @Published public private(set) var state: AnalysisState<[DuplicateGroup]> = .idle
    @Published public var selectedItemIds: Set<String> = []

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
            let allVideos = PhotoLibraryService.shared.fetchVideos()
            let videos = allVideos.filter { !TrashManager.shared.isTrashed(id: $0.id) }
            let total = videos.count

            guard total > 0 else {
                state = .empty
                return
            }

            for await update in await DuplicateVideoAnalyzer.analyze(items: videos) {
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
        let allItems = groups.flatMap { $0.items }
        let selected = allItems.filter { selectedItemIds.contains($0.id) }

        guard !selected.isEmpty else { return }

        TrashManager.shared.moveToTrash(items: selected)
        selectedItemIds.removeAll()
        startAnalysis()
    }
}
