import SwiftUI

public enum MediaCategory: String, CaseIterable, Identifiable, Sendable {
    case screenshots
    case videos
    case duplicatePhotos
    case similarPhotos
    case similarVideos
    case duplicateVideos
    case largeVideos

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .screenshots: return "Screenshots"
        case .videos: return "Videos"
        case .duplicatePhotos: return "Duplicate Photos"
        case .similarPhotos: return "Similar Photos"
        case .similarVideos: return "Similar Videos"
        case .duplicateVideos: return "Duplicate Videos"
        case .largeVideos: return "Large Videos"
        }
    }

    public var subtitle: String {
        switch self {
        case .screenshots: return "Clean up screen captures"
        case .videos: return "Browse all recorded videos"
        case .duplicatePhotos: return "Exact photo duplicates"
        case .similarPhotos: return "Visually similar shots"
        case .similarVideos: return "Visually similar video clips"
        case .duplicateVideos: return "Exact video duplicates"
        case .largeVideos: return "Videos taking most space"
        }
    }

    public var iconName: String {
        switch self {
        case .screenshots: return "crop"
        case .videos: return "video.fill"
        case .duplicatePhotos: return "doc.on.doc.fill"
        case .similarPhotos: return "photo.on.rectangle.angled"
        case .similarVideos: return "film"
        case .duplicateVideos: return "film.stack.fill"
        case .largeVideos: return "arrow.up.left.and.arrow.down.right.circle.fill"
        }
    }

    public var themeColor: Color {
        switch self {
        case .screenshots: return .blue
        case .videos: return .purple
        case .duplicatePhotos: return .orange
        case .similarPhotos: return .pink
        case .similarVideos: return .teal
        case .duplicateVideos: return .indigo
        case .largeVideos: return .red
        }
    }
}
