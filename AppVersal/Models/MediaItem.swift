import Foundation
import Photos

public struct MediaItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let asset: PHAsset
    public let creationDate: Date?
    public let pixelWidth: Int
    public let pixelHeight: Int
    public let duration: TimeInterval
    public var fileSize: Int64?
    public let mediaType: PHAssetMediaType
    public let mediaSubtypes: PHAssetMediaSubtype

    public nonisolated init(asset: PHAsset, fileSize: Int64? = nil) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.creationDate = asset.creationDate
        self.pixelWidth = asset.pixelWidth
        self.pixelHeight = asset.pixelHeight
        self.duration = asset.duration
        self.fileSize = fileSize
        self.mediaType = asset.mediaType
        self.mediaSubtypes = asset.mediaSubtypes
    }

    public nonisolated var isScreenshot: Bool {
        mediaSubtypes.contains(.photoScreenshot) || PhotoLibraryService.isLikelyScreenshot(asset: asset)
    }

    public nonisolated var isVideo: Bool {
        mediaType == .video
    }

    public nonisolated var isPhoto: Bool {
        mediaType == .image && !isScreenshot
    }

    public nonisolated var formattedSize: String {
        guard let size = fileSize, size > 0 else { return "" }
        return ByteFormatter.format(size)
    }

    public nonisolated var dimensionsString: String {
        guard pixelWidth > 0 && pixelHeight > 0 else { return "" }
        return "\(pixelWidth) × \(pixelHeight)"
    }

    public nonisolated var formattedDuration: String {
        guard isVideo else { return "" }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = duration >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "0:00"
    }

    public nonisolated static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        lhs.id == rhs.id
    }

    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
