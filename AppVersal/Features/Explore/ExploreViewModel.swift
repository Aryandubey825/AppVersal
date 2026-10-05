//
//  ExploreViewModel.swift
//  AppVersal
//

import SwiftUI
import Photos
import Combine
import OSLog

public struct MonthGroup: Identifiable, Hashable, Sendable {
    public let id: String
    public let year: Int
    public let month: Int
    public let title: String
    public var items: [MediaItem]
    public let previewAsset: PHAsset?

    public init(id: String, year: Int, month: Int, title: String, items: [MediaItem], previewAsset: PHAsset?) {
        self.id = id
        self.year = year
        self.month = month
        self.title = title
        self.items = items
        self.previewAsset = previewAsset
    }

    public var totalSizeBytes: Int64 {
        items.compactMap { $0.fileSize }.reduce(0, +)
    }

    public var formattedTotalSize: String {
        ByteFormatter.format(totalSizeBytes)
    }

    public static func == (lhs: MonthGroup, rhs: MonthGroup) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public struct YearlyGroup: Identifiable, Hashable, Sendable {
    public let year: Int
    public var months: [MonthGroup]
    public var items: [MediaItem]
    public let previewAsset: PHAsset?

    public init(year: Int, months: [MonthGroup], items: [MediaItem], previewAsset: PHAsset? = nil) {
        self.year = year
        self.months = months
        self.items = items
        self.previewAsset = previewAsset
    }

    public var id: Int { year }

    public var totalSizeBytes: Int64 {
        items.compactMap { $0.fileSize }.reduce(0, +)
    }

    public var formattedTotalSize: String {
        ByteFormatter.format(totalSizeBytes)
    }

    public static func == (lhs: YearlyGroup, rhs: YearlyGroup) -> Bool {
        lhs.year == rhs.year
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(year)
    }
}

@MainActor
public final class ExploreViewModel: ObservableObject {
    @Published public private(set) var yearlyGroups: [YearlyGroup] = []
    @Published public private(set) var allMonths: [MonthGroup] = []
    @Published public private(set) var allActiveItems: [MediaItem] = []
    @Published public private(set) var isLoading: Bool = false

    private let libraryService = PhotoLibraryService.shared
    private var cancellables = Set<AnyCancellable>()

    public init() {
        setupObservers()
    }

    public func loadYearlyGallery() {
        isLoading = true
        Task.detached(priority: .userInitiated) {
            let photos = PhotoLibraryService.shared.fetchAllPhotos()
            let videos = PhotoLibraryService.shared.fetchVideos()

            let activePhotos = await MainActor.run {
                photos.filter { !TrashManager.shared.isTrashed(id: $0.id) }
            }
            let activeVideos = await MainActor.run {
                videos.filter { !TrashManager.shared.isTrashed(id: $0.id) }
            }

            let allItems = (activePhotos + activeVideos).sorted {
                ($0.creationDate ?? Date.distantPast) > ($1.creationDate ?? Date.distantPast)
            }

            let calendar = Calendar.current
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM yyyy"

            // Group by Month (Year + Month key)
            var monthlyBucket: [String: (year: Int, month: Int, title: String, items: [MediaItem])] = [:]

            for item in allItems {
                let date = item.creationDate ?? Date()
                let components = calendar.dateComponents([.year, .month], from: date)
                let year = components.year ?? 2000
                let month = components.month ?? 1
                let key = String(format: "%04d-%02d", year, month)
                let title = dateFormatter.string(from: date)

                if var existing = monthlyBucket[key] {
                    existing.items.append(item)
                    monthlyBucket[key] = existing
                } else {
                    monthlyBucket[key] = (year: year, month: month, title: title, items: [item])
                }
            }

            // Sort months newest first
            let sortedKeys = monthlyBucket.keys.sorted(by: >)
            let monthGroups = sortedKeys.compactMap { key -> MonthGroup? in
                guard let data = monthlyBucket[key] else { return nil }
                return MonthGroup(
                    id: key,
                    year: data.year,
                    month: data.month,
                    title: data.title,
                    items: data.items,
                    previewAsset: data.items.first?.asset
                )
            }

            // Group months by year
            var yearBucket: [Int: [MonthGroup]] = [:]
            for month in monthGroups {
                yearBucket[month.year, default: []].append(month)
            }

            let sortedYears = yearBucket.keys.sorted(by: >)
            let yearlyGroups = sortedYears.map { year in
                let months = yearBucket[year] ?? []
                let allYearItems = months.flatMap { $0.items }
                return YearlyGroup(
                    year: year,
                    months: months,
                    items: allYearItems,
                    previewAsset: allYearItems.first?.asset
                )
            }

            await MainActor.run {
                self.allActiveItems = allItems
                self.allMonths = monthGroups
                self.yearlyGroups = yearlyGroups
                self.isLoading = false
            }
        }
    }

    private func setupObservers() {
        libraryService.changePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadYearlyGallery()
            }
            .store(in: &cancellables)

        TrashManager.shared.$trashedItems
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadYearlyGallery()
            }
            .store(in: &cancellables)
    }
}
