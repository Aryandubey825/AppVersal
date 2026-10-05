import Foundation

public struct SimilarGroup: Identifiable, Hashable, Sendable {
    public let id: String
    public let primaryItem: MediaItem
    public var similarItems: [MediaItem]
    public let averageSimilarityScore: Float

    public nonisolated init(id: String = UUID().uuidString, primaryItem: MediaItem, similarItems: [MediaItem], averageSimilarityScore: Float) {
        self.id = id
        self.primaryItem = primaryItem
        self.similarItems = similarItems
        self.averageSimilarityScore = averageSimilarityScore
    }

    public nonisolated var allItems: [MediaItem] {
        [primaryItem] + similarItems
    }
}
