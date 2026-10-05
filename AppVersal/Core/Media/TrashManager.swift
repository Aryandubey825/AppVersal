//
//  TrashManager.swift
//  AppVersal
//

import Foundation
import Photos
import Combine
import SwiftUI
import OSLog

@MainActor
public final class TrashManager: ObservableObject {
    public static let shared = TrashManager()

    @Published public private(set) var trashedItems: [MediaItem] = []

    private let userDefaultsKey = "appversal_trashed_asset_ids"
    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadTrashedItems()
        setupObservers()
    }

    private func setupObservers() {
        PhotoLibraryService.shared.libraryUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.loadTrashedItems()
            }
            .store(in: &cancellables)
    }

    public func isTrashed(id: String) -> Bool {
        trashedItems.contains(where: { $0.id == id })
    }

    public func moveToTrash(items: [MediaItem]) {
        var current = trashedItems
        for item in items {
            if !current.contains(where: { $0.id == item.id }) {
                current.append(item)
            }
            HeroThumbnailCache.shared.removeImage(for: item.id)
        }
        trashedItems = current
        saveTrashedIds()
        AppLogger.photos.info("Moved \(items.count) items to in-app Trash")
    }

    public func restore(items: [MediaItem]) {
        let removeIds = Set(items.map { $0.id })
        trashedItems.removeAll { removeIds.contains($0.id) }
        saveTrashedIds()
        AppLogger.photos.info("Restored \(items.count) items from Trash")
    }

    public func deletePermanently(items: [MediaItem]) async throws {
        let assets = items.map { $0.asset }
        try await PhotoLibraryService.shared.deleteAssets(assets)
        let removeIds = Set(items.map { $0.id })
        trashedItems.removeAll { removeIds.contains($0.id) }
        for item in items {
            HeroThumbnailCache.shared.removeImage(for: item.id)
        }
        saveTrashedIds()
        AppLogger.photos.info("Permanently deleted \(items.count) items from device")
    }

    public func emptyTrash() async throws {
        let assets = trashedItems.map { $0.asset }
        if !assets.isEmpty {
            try await PhotoLibraryService.shared.deleteAssets(assets)
        }
        for item in trashedItems {
            HeroThumbnailCache.shared.removeImage(for: item.id)
        }
        trashedItems.removeAll()
        saveTrashedIds()
        AppLogger.photos.info("Emptied Trash")
    }

    public var totalTrashSizeByte: Int64 {
        trashedItems.compactMap { $0.fileSize }.reduce(0, +)
    }

    private func saveTrashedIds() {
        let ids = trashedItems.map { $0.id }
        UserDefaults.standard.set(ids, forKey: userDefaultsKey)
    }

    public func loadTrashedItems() {
        guard let savedIds = UserDefaults.standard.stringArray(forKey: userDefaultsKey), !savedIds.isEmpty else {
            trashedItems = []
            return
        }

        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: savedIds, options: nil)
        var items: [MediaItem] = []
        fetchResult.enumerateObjects { asset, _, _ in
            items.append(MediaItem(asset: asset, fileSize: PhotoLibraryService.getFileSize(for: asset)))
        }
        self.trashedItems = items
    }
}
