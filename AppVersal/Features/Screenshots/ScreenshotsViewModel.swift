import SwiftUI
import Photos
import Combine
import OSLog

@MainActor
public final class ScreenshotsViewModel: ObservableObject {
    @Published public private(set) var items: [MediaItem] = []
    @Published public private(set) var isLoading: Bool = false
    @Published public var selectedItemIds: Set<String> = []
    @Published public var selectedDateFilter: DateFilterOption = .all

    public var filteredItems: [MediaItem] {
        guard selectedDateFilter.isFiltered else { return items }
        return items.filter { selectedDateFilter.matches(date: $0.creationDate) }
    }

    private var cancellables = Set<AnyCancellable>()

    public init() {
        setupObservers()
    }

    private func setupObservers() {
        PhotoLibraryService.shared.libraryUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.loadScreenshots()
            }
            .store(in: &cancellables)
    }

    public func loadScreenshots() {
        if items.isEmpty {
            isLoading = true
        }
        let trashedIds = Set(TrashManager.shared.trashedItems.map { $0.id })
        Task.detached(priority: .userInitiated) {
            let fetched = PhotoLibraryService.shared.fetchScreenshots()
            let filtered = fetched.filter { !trashedIds.contains($0.id) }
            await MainActor.run {
                self.items = filtered
                self.isLoading = false
            }
        }
    }

    public func toggleSelection(id: String) {
        if selectedItemIds.contains(id) {
            selectedItemIds.remove(id)
        } else {
            selectedItemIds.insert(id)
        }
    }

    public func deleteSelected() {
        let selected = items.filter { selectedItemIds.contains($0.id) }
        guard !selected.isEmpty else { return }

        TrashManager.shared.moveToTrash(items: selected)
        let deletedIds = selectedItemIds
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            items.removeAll { deletedIds.contains($0.id) }
            selectedItemIds.removeAll()
        }
    }
}
