import Foundation

public struct SimilarGroup: Identifiable, Hashable, Sendable {
    public let id: String
    public let primaryItem: MediaItem
    public var similarItems: [MediaItem]
    public let averageSimilarityScore: Float
    public var selectedKeepId: String?

    public nonisolated init(
        id: String = UUID().uuidString,
        primaryItem: MediaItem,
        similarItems: [MediaItem],
        averageSimilarityScore: Float,
        selectedKeepId: String? = nil
    ) {
        self.id = id
        self.primaryItem = primaryItem
        self.similarItems = similarItems
        self.averageSimilarityScore = averageSimilarityScore
        self.selectedKeepId = selectedKeepId ?? primaryItem.id
    }

    /// Convenience cluster initializer matching GalleryCleaner
    public nonisolated init(
        id: String = UUID().uuidString,
        items: [MediaItem],
        similarityScore: Double = 0.92,
        selectedKeepId: String? = nil
    ) {
        precondition(!items.isEmpty, "SimilarGroup requires at least one item")
        let keepId = selectedKeepId ?? items.max(by: { ($0.fileSize ?? 0) < ($1.fileSize ?? 0) })?.id ?? items[0].id
        let best = items.first { $0.id == keepId } ?? items[0]
        let others = items.filter { $0.id != best.id }

        self.id = id
        self.primaryItem = best
        self.similarItems = others
        self.averageSimilarityScore = Float(similarityScore)
        self.selectedKeepId = keepId
    }

    public nonisolated var allItems: [MediaItem] {
        [primaryItem] + similarItems
    }

    public nonisolated var items: [MediaItem] {
        allItems
    }

    public nonisolated var bestItem: MediaItem? {
        items.first { $0.id == selectedKeepId } ?? primaryItem
    }

    public nonisolated var removableItems: [MediaItem] {
        guard let keepId = selectedKeepId else { return similarItems }
        return items.filter { $0.id != keepId }
    }

    public nonisolated var reclaimableSpace: Int64 {
        removableItems.compactMap { $0.fileSize }.reduce(0, +)
    }

    public nonisolated var formattedReclaimableSpace: String {
        ByteFormatter.format(reclaimableSpace)
    }

    public nonisolated var formattedScore: String {
        let percent = Int(averageSimilarityScore * 100)
        return "\(percent)% match"
    }
}
