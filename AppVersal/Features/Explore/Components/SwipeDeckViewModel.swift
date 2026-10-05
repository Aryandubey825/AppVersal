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
    public let initialCount: Int

    @Published public private(set) var remainingItems: [MediaItem]
    @Published public private(set) var keptItems: [MediaItem] = []
    @Published public private(set) var trashedItems: [MediaItem] = []
    @Published public private(set) var history: [SwipeHistoryItem] = []
    @Published public private(set) var isCompleted: Bool = false

    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let lightFeedback = UIImpactFeedbackGenerator(style: .light)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    public init(title: String, items: [MediaItem]) {
        self.title = title
        self.remainingItems = items
        self.initialCount = items.count
        self.isCompleted = items.isEmpty
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
        remainingItems.removeFirst()
        checkCompletion()
    }

    public func trashCurrent() {
        guard let item = currentItem else { return }
        impactFeedback.impactOccurred()
        trashedItems.append(item)
        history.append(SwipeHistoryItem(item: item, action: .trash))
        TrashManager.shared.moveToTrash(items: [item])
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
