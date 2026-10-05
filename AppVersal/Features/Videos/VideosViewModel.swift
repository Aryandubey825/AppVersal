//
//  VideosViewModel.swift
//  AppVersal
//

import SwiftUI
import Photos
import Combine
import OSLog

@MainActor
public final class VideosViewModel: ObservableObject {
    @Published public private(set) var items: [MediaItem] = []
    @Published public private(set) var isLoading: Bool = false
    @Published public var selectedItemIds: Set<String> = []

    public init() {}

    public func loadVideos() {
        isLoading = true
        Task.detached(priority: .userInitiated) {
            let fetched = PhotoLibraryService.shared.fetchVideos()
            let filtered = await MainActor.run {
                fetched.filter { !TrashManager.shared.isTrashed(id: $0.id) }
            }
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
        selectedItemIds.removeAll()
        loadVideos()
    }
}
