import Foundation

public struct DuplicateGroup: Identifiable, Hashable, Sendable {
    public let id: String
    public let fingerprint: String
    public var items: [MediaItem]

    public nonisolated init(id: String = UUID().uuidString, fingerprint: String, items: [MediaItem]) {
        self.id = id
        self.fingerprint = fingerprint
        self.items = items
    }

    public nonisolated var totalSizeByte: Int64 {
        items.compactMap { $0.fileSize }.reduce(0, +)
    }

    public nonisolated var reclaimableSizeByte: Int64 {
        guard items.count > 1 else { return 0 }
        let perItemSize = items.first?.fileSize ?? 0
        return perItemSize * Int64(items.count - 1)
    }
}
