//
//  HomeViewModel.swift
//  AppVersal
//

import SwiftUI
import Photos
import Combine
import OSLog

@MainActor
public final class HomeViewModel: ObservableObject {
    @Published public var categoryCounts: [MediaCategory: Int] = [:]
    @Published public var previewAssets: [MediaCategory: PHAsset] = [:]
    @Published public var previewImages: [MediaCategory: UIImage] = [:]
    @Published public var totalPhotosCount: Int = 0
    @Published public var totalVideosCount: Int = 0
    @Published public var largeVideoTotalSize: Int64 = 0
    @Published public var isAuthorizationGranted: Bool = false
    @Published public var isLimitedAccess: Bool = false

    // Device Storage
    @Published public var totalDeviceStorage: Int64 = 0
    @Published public var usedDeviceStorage: Int64 = 0
    @Published public var freeDeviceStorage: Int64 = 0
    @Published public var storageUsedRatio: Double = 0.0

    private let libraryService = PhotoLibraryService.shared
    private let authService = PhotoAuthorizationService()
    private var cancellables = Set<AnyCancellable>()
    public private(set) var hasLoadedInitially: Bool = false

    public init() {
        calculateDeviceStorage()
        setupObservers()
    }

    public func calculateDeviceStorage() {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory())
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey])
            if let total = values.volumeTotalCapacity, let available = values.volumeAvailableCapacityForImportantUsage {
                let totalBytes = Int64(total)
                let freeBytes = available
                let usedBytes = max(0, totalBytes - freeBytes)
                self.totalDeviceStorage = totalBytes
                self.freeDeviceStorage = freeBytes
                self.usedDeviceStorage = usedBytes
                self.storageUsedRatio = totalBytes > 0 ? Double(usedBytes) / Double(totalBytes) : 0.0
                return
            }
        } catch {}

        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            let total = attrs[.systemSize] as? Int64 ?? 128_000_000_000
            let free = attrs[.systemFreeSize] as? Int64 ?? 54_000_000_000
            let used = max(0, total - free)
            self.totalDeviceStorage = total
            self.freeDeviceStorage = free
            self.usedDeviceStorage = used
            self.storageUsedRatio = total > 0 ? Double(used) / Double(total) : 0.0
        }
    }

    public func loadCounts(force: Bool = false) async {
        if hasLoadedInitially && !force {
            return
        }
        hasLoadedInitially = true

        calculateDeviceStorage()

        _ = await authService.requestAuthorization()
        self.isAuthorizationGranted = authService.isAuthorized
        self.isLimitedAccess = authService.isLimited

        guard isAuthorizationGranted else { return }

        // Fetch raw assets
        let allPhotos = libraryService.fetchAllPhotos()
        let allVideos = libraryService.fetchVideos()
        let allScreenshots = libraryService.fetchScreenshots()

        // Filter out items in Trash
        let activePhotos = allPhotos.filter { !TrashManager.shared.isTrashed(id: $0.id) }
        let activeVideos = allVideos.filter { !TrashManager.shared.isTrashed(id: $0.id) }
        let activeScreenshots = allScreenshots.filter { !TrashManager.shared.isTrashed(id: $0.id) }

        self.totalPhotosCount = activePhotos.count
        self.totalVideosCount = activeVideos.count

        var counts: [MediaCategory: Int] = [:]
        counts[.screenshots] = activeScreenshots.count
        counts[.videos] = activeVideos.count
        counts[.duplicateVideos] = self.categoryCounts[.duplicateVideos] ?? 0
        counts[.similarVideos] = self.categoryCounts[.similarVideos] ?? 0
        counts[.largeVideos] = activeVideos.count
        counts[.duplicatePhotos] = self.categoryCounts[.duplicatePhotos] ?? 0
        counts[.similarPhotos] = self.categoryCounts[.similarPhotos] ?? 0
        self.categoryCounts = counts

        // Retain stable preview assets without clearing
        setStablePreview(for: .screenshots, candidate: activeScreenshots.first?.asset, activeIds: Set(activeScreenshots.map { $0.id }))
        setStablePreview(for: .videos, candidate: activeVideos.first?.asset, activeIds: Set(activeVideos.map { $0.id }))

        let sortedVideos = activeVideos.sorted { ($0.fileSize ?? 0) > ($1.fileSize ?? 0) }
        setStablePreview(for: .largeVideos, candidate: sortedVideos.first?.asset, activeIds: Set(sortedVideos.map { $0.id }))

        let totalBytes = activeVideos.compactMap { $0.fileSize }.reduce(0, +)
        self.largeVideoTotalSize = totalBytes

        // Background quick scan for real duplicates and similar photos/videos
        Task.detached(priority: .userInitiated) {
            let dupResult = await DuplicatePhotoAnalyzer.quickScan(items: activePhotos)
            let simResult = await SimilarPhotoAnalyzer.quickScan(items: activePhotos)
            let dupVidResult = await DuplicateVideoAnalyzer.quickScan(items: activeVideos)
            let simVidResult = await SimilarVideoAnalyzer.quickScan(items: activeVideos)

            let activePhotoIds = Set(activePhotos.map { $0.id })
            let activeVideoIds = Set(activeVideos.map { $0.id })

            await MainActor.run {
                self.categoryCounts[.duplicatePhotos] = dupResult.count
                self.categoryCounts[.similarPhotos] = simResult.count
                self.categoryCounts[.duplicateVideos] = dupVidResult.count
                self.categoryCounts[.similarVideos] = simVidResult.count

                self.setStablePreview(for: .duplicatePhotos, candidate: dupResult.previewAsset, activeIds: activePhotoIds)
                self.setStablePreview(for: .similarPhotos, candidate: simResult.previewAsset, activeIds: activePhotoIds)
                self.setStablePreview(for: .duplicateVideos, candidate: dupVidResult.previewAsset, activeIds: activeVideoIds)
                self.setStablePreview(for: .similarVideos, candidate: simVidResult.previewAsset, activeIds: activeVideoIds)
            }
        }
    }

    /// Preserves existing preview image and asset if still active, preventing card image flicker
    private func setStablePreview(for category: MediaCategory, candidate: PHAsset?, activeIds: Set<String>) {
        if let current = previewAssets[category] {
            // If current asset is still active and not trashed/deleted, and we already have an image in memory, keep it completely stable!
            if activeIds.contains(current.localIdentifier) && previewImages[category] != nil {
                return
            }
        }

        // If candidate is available, update and pre-warm thumbnail cache
        if let candidate = candidate {
            previewAssets[category] = candidate

            // Check cache synchronously first for instant UI response
            if let cached = HeroThumbnailCache.shared.image(for: candidate.localIdentifier) {
                previewImages[category] = cached
            } else {
                Task {
                    if let image = await HeroThumbnailCache.shared.loadThumbnail(for: candidate) {
                        self.previewImages[category] = image
                    }
                }
            }
        } else {
            previewAssets.removeValue(forKey: category)
            previewImages.removeValue(forKey: category)
        }
    }

    private func setupObservers() {
        libraryService.libraryUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                Task {
                    await self?.loadCounts(force: true)
                }
            }
            .store(in: &cancellables)

        libraryService.changePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.loadCounts(force: true)
                }
            }
            .store(in: &cancellables)

        TrashManager.shared.$trashedItems
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.loadCounts(force: true)
                }
            }
            .store(in: &cancellables)
    }
}
