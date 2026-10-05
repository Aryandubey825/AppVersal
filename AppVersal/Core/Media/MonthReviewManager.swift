//
//  MonthReviewManager.swift
//  AppVersal
//

import Foundation
import Combine

@MainActor
public final class MonthReviewManager: ObservableObject {
    public static let shared = MonthReviewManager()

    @Published private var keptItemIds: [String: Set<String>] = [:]
    @Published private var trashedItemIds: [String: Set<String>] = [:]
    @Published private var trashedBytesMap: [String: Int64] = [:]

    private let keptKey = "appversal_month_kept_ids"
    private let trashedKey = "appversal_month_trashed_ids"
    private let bytesKey = "appversal_month_trashed_bytes"
    private let migrationKey = "appversal_has_reset_stale_stats_v3"

    private init() {
        if !UserDefaults.standard.bool(forKey: migrationKey) {
            resetAll()
            UserDefaults.standard.set(true, forKey: migrationKey)
        } else {
            loadData()
        }
    }

    public func stats(for monthId: String, totalItems: Int) -> (swipedCount: Int, keptCount: Int, trashedCount: Int, percentage: Int, trashedBytes: Int64) {
        let kept = keptItemIds[monthId]?.count ?? 0
        let trashed = trashedItemIds[monthId]?.count ?? 0
        let swiped = min(totalItems, kept + trashed)
        let percentage = totalItems > 0 ? Int((Double(swiped) / Double(totalItems)) * 100) : 0
        let bytes = trashedBytesMap[monthId] ?? 0
        return (swiped, kept, trashed, min(100, percentage), bytes)
    }

    public func resetMonth(_ monthId: String) {
        keptItemIds.removeValue(forKey: monthId)
        trashedItemIds.removeValue(forKey: monthId)
        trashedBytesMap.removeValue(forKey: monthId)
        saveData()
    }

    public func resetAll() {
        keptItemIds.removeAll()
        trashedItemIds.removeAll()
        trashedBytesMap.removeAll()
        UserDefaults.standard.removeObject(forKey: keptKey)
        UserDefaults.standard.removeObject(forKey: trashedKey)
        UserDefaults.standard.removeObject(forKey: bytesKey)
    }

    public func recordKeep(id: String, monthId: String) {
        var set = keptItemIds[monthId] ?? []
        set.insert(id)
        keptItemIds[monthId] = set
        saveData()
    }

    public func recordTrash(id: String, fileSize: Int64 = 0, monthId: String) {
        var set = trashedItemIds[monthId] ?? []
        set.insert(id)
        trashedItemIds[monthId] = set
        if fileSize > 0 {
            trashedBytesMap[monthId] = (trashedBytesMap[monthId] ?? 0) + fileSize
        }
        saveData()
    }

    public func recordUndo(id: String, fileSize: Int64 = 0, monthId: String) {
        if var kept = keptItemIds[monthId] {
            kept.remove(id)
            keptItemIds[monthId] = kept
        }
        if var trashed = trashedItemIds[monthId] {
            trashed.remove(id)
            trashedItemIds[monthId] = trashed
            if fileSize > 0 {
                let current = trashedBytesMap[monthId] ?? 0
                trashedBytesMap[monthId] = max(0, current - fileSize)
            }
        }
        saveData()
    }

    private func saveData() {
        let keptDict = keptItemIds.mapValues { Array($0) }
        let trashedDict = trashedItemIds.mapValues { Array($0) }
        UserDefaults.standard.set(keptDict, forKey: keptKey)
        UserDefaults.standard.set(trashedDict, forKey: trashedKey)
        UserDefaults.standard.set(trashedBytesMap, forKey: bytesKey)
    }

    private func loadData() {
        if let keptDict = UserDefaults.standard.dictionary(forKey: keptKey) as? [String: [String]] {
            self.keptItemIds = keptDict.mapValues { Set($0) }
        }
        if let trashedDict = UserDefaults.standard.dictionary(forKey: trashedKey) as? [String: [String]] {
            self.trashedItemIds = trashedDict.mapValues { Set($0) }
        }
        if let bytesDict = UserDefaults.standard.dictionary(forKey: bytesKey) as? [String: Int64] {
            self.trashedBytesMap = bytesDict
        }
    }
}
