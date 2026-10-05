//
//  TrashViewModel.swift
//  AppVersal
//

import SwiftUI
import Photos
import Combine
import OSLog

@MainActor
public final class TrashViewModel: ObservableObject {
    @Published public var totalSpaceFreedBytes: Int64 = 0
    @Published public var totalItemsCleanedCount: Int = 0

    private let userDefaultsKeyFreed = "appversal_trash_space_freed"
    private let userDefaultsKeyCount = "appversal_trash_items_count"

    public init() {
        loadStats()
    }

    public func recordCleaned(itemCount: Int, sizeBytes: Int64) {
        totalItemsCleanedCount += itemCount
        totalSpaceFreedBytes += sizeBytes
        UserDefaults.standard.set(totalSpaceFreedBytes, forKey: userDefaultsKeyFreed)
        UserDefaults.standard.set(totalItemsCleanedCount, forKey: userDefaultsKeyCount)
    }

    public func loadStats() {
        totalSpaceFreedBytes = UserDefaults.standard.object(forKey: userDefaultsKeyFreed) as? Int64 ?? 0
        totalItemsCleanedCount = UserDefaults.standard.integer(forKey: userDefaultsKeyCount)
    }

    public func resetStats() {
        totalSpaceFreedBytes = 0
        totalItemsCleanedCount = 0
        UserDefaults.standard.removeObject(forKey: userDefaultsKeyFreed)
        UserDefaults.standard.removeObject(forKey: userDefaultsKeyCount)
    }

    public func openSystemPhotosApp() {
        if let url = URL(string: "photos-redirect://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}
