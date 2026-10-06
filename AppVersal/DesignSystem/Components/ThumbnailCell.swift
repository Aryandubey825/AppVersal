import SwiftUI
import UIKit
import Photos

public struct ThumbnailCell: View {
    public let item: MediaItem
    public let isSelected: Bool
    public let isBest: Bool
    public let onSelectToggle: (() -> Void)?

    @State private var image: UIImage? = nil

    public init(item: MediaItem, isSelected: Bool = false, isBest: Bool = false, onSelectToggle: (() -> Void)? = nil) {
        self.item = item
        self.isSelected = isSelected
        self.isBest = isBest
        self.onSelectToggle = onSelectToggle
    }

    public var body: some View {
        Button {
            onSelectToggle?()
        } label: {
            ZStack(alignment: .bottomTrailing) {
                GeometryReader { geo in
                    ZStack(alignment: .topTrailing) {
                        if let img = image {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(Color(UIColor.systemGray5))
                                .overlay(
                                    Image(systemName: item.isVideo ? "video" : "photo")
                                        .foregroundColor(.secondary)
                                )
                        }

                        if isBest {
                            VStack {
                                HStack {
                                    Text("BEST")
                                        .font(.system(size: 9, weight: .heavy))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.blue)
                                        .clipShape(Capsule())
                                        .padding(4)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }

                        if onSelectToggle != nil {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? Color.blue : Color.black.opacity(0.35))
                                    .frame(width: 26, height: 26)

                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.white)
                                } else {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 22, height: 22)
                                }
                            }
                            .frame(width: 44, height: 44)
                            .padding(2)
                        }
                    }
                }
                .aspectRatio(1, contentMode: .fit)

                if item.isVideo {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.caption2)
                        Text(item.formattedDuration)
                            .font(.caption2.bold())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.65))
                    .cornerRadius(4)
                    .padding(6)
                } else if let size = item.fileSize {
                    Text(ByteFormatter.format(size))
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.65))
                        .cornerRadius(4)
                        .padding(6)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.isVideo ? "Video, duration \(item.formattedDuration)" : "Photo")
        .accessibilityValue(item.fileSize != nil ? ByteFormatter.format(item.fileSize!) : "")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
        .accessibilityHint("Double tap to toggle selection")
        .task {
            if image == nil {
                image = await MediaThumbnailService.shared.requestImage(for: item.asset)
            }
        }
    }
}
