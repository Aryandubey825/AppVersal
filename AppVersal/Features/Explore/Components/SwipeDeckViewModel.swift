//
//  SwipeDeckViewModel.swift
//  AppVersal
//

import SwiftUI
import Photos
import Combine
import UIKit

public enum SwipeAction: Sendable {
    case keep
    case trash
}

public struct SwipeHistoryItem: Sendable {
    public let item: MediaItem
    public let action: SwipeAction
}

@MainActor
public final class SwipeDeckViewModel: ObservableObject {
    public let title: String
    public let monthId: String?
    @Published public private(set) var initialCount: Int

    @Published public private(set) var remainingItems: [MediaItem]
    @Published public private(set) var keptItems: [MediaItem] = []
    @Published public private(set) var trashedItems: [MediaItem] = []
    @Published public private(set) var history: [SwipeHistoryItem] = []
    @Published public private(set) var isCompleted: Bool = false

    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let lightFeedback = UIImpactFeedbackGenerator(style: .light)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    private var cancellables = Set<AnyCancellable>()

    public init(title: String, items: [MediaItem], monthId: String? = nil) {
        self.title = title
        self.monthId = monthId
        self.remainingItems = items
        self.initialCount = items.count
        self.isCompleted = items.isEmpty
        if let mid = monthId {
            MonthReviewManager.shared.resetMonth(mid)
        }
        setupObservers()
    }

    private func setupObservers() {
        guard let monthId = monthId else { return }
        PhotoLibraryService.shared.libraryUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.refreshMonthItems(monthId: monthId)
            }
            .store(in: &cancellables)
    }

    private func refreshMonthItems(monthId: String) {
        let parts = monthId.split(separator: "-")
        guard parts.count == 2, let year = Int(parts[0]), let month = Int(parts[1]) else { return }

        let photos = PhotoLibraryService.shared.fetchAllPhotos()
        let videos = PhotoLibraryService.shared.fetchVideos()
        let trashedIds = Set(TrashManager.shared.trashedItems.map { $0.id })
        let allActive = (photos + videos).filter { !trashedIds.contains($0.id) }

        let calendar = Calendar.current
        let freshMonthItems = allActive.filter { item in
            guard let date = item.creationDate else { return false }
            let comps = calendar.dateComponents([.year, .month], from: date)
            return comps.year == year && comps.month == month
        }.sorted { ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast) }

        let handledIds = Set(keptItems.map { $0.id } + trashedItems.map { $0.id })
        let currentRemainingIds = Set(remainingItems.map { $0.id })
        let newlyDiscovered = freshMonthItems.filter { !handledIds.contains($0.id) && !currentRemainingIds.contains($0.id) }

        if !newlyDiscovered.isEmpty {
            self.remainingItems.append(contentsOf: newlyDiscovered)
            self.initialCount = self.keptItems.count + self.trashedItems.count + self.remainingItems.count
            self.isCompleted = self.remainingItems.isEmpty
        }
    }

    public var currentItem: MediaItem? {
        remainingItems.first
    }

    public var nextItem: MediaItem? {
        remainingItems.count > 1 ? remainingItems[1] : nil
    }

    public var progress: Double {
        guard initialCount > 0 else { return 1.0 }
        let swiped = initialCount - remainingItems.count
        return Double(swiped) / Double(initialCount)
    }

    public var swipedCount: Int {
        initialCount - remainingItems.count
    }

    public var canUndo: Bool {
        !history.isEmpty
    }

    public var totalTrashedBytes: Int64 {
        trashedItems.compactMap { $0.fileSize }.reduce(0, +)
    }

    public func keepCurrent() {
        guard let item = currentItem else { return }
        lightFeedback.impactOccurred()
        keptItems.append(item)
        history.append(SwipeHistoryItem(item: item, action: .keep))
        if let mid = monthId {
            MonthReviewManager.shared.recordKeep(id: item.id, monthId: mid)
        }
        remainingItems.removeFirst()
        checkCompletion()
    }

    public func trashCurrent() {
        guard let item = currentItem else { return }
        impactFeedback.impactOccurred()
        trashedItems.append(item)
        history.append(SwipeHistoryItem(item: item, action: .trash))
        TrashManager.shared.moveToTrash(items: [item])
        if let mid = monthId {
            MonthReviewManager.shared.recordTrash(id: item.id, fileSize: item.fileSize ?? 0, monthId: mid)
        }
        remainingItems.removeFirst()
        checkCompletion()
    }

    public func undoLast() {
        guard let last = history.popLast() else { return }
        lightFeedback.impactOccurred()

        switch last.action {
        case .keep:
            keptItems.removeAll { $0.id == last.item.id }
        case .trash:
            trashedItems.removeAll { $0.id == last.item.id }
            TrashManager.shared.restore(items: [last.item])
        }

        if let mid = monthId {
            MonthReviewManager.shared.recordUndo(id: last.item.id, fileSize: last.item.fileSize ?? 0, monthId: mid)
        }

        remainingItems.insert(last.item, at: 0)
        isCompleted = false
    }

    private func checkCompletion() {
        if remainingItems.isEmpty {
            notificationFeedback.notificationOccurred(.success)
            isCompleted = true
        }
    }
}
