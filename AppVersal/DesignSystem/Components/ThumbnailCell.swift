//
//  ThumbnailCell.swift
//  AppVersal
//

import SwiftUI
import UIKit
import Photos
import Combine

public struct ThumbnailCell: View {
    public let item: MediaItem
    public let isSelected: Bool
    public let onSelectToggle: (() -> Void)?

    @State private var image: UIImage? = nil

    public init(item: MediaItem, isSelected: Bool = false, onSelectToggle: (() -> Void)? = nil) {
        self.item = item
        self.isSelected = isSelected
        self.onSelectToggle = onSelectToggle
    }

    public var body: some View {
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

                    if let toggle = onSelectToggle {
                        Button(action: toggle) {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? Color.blue : Color.black.opacity(0.3))
                                    .frame(width: 26, height: 26)

                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 22, height: 22)
                                }
                            }
                            .padding(6)
                        }
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)

            // Video Duration & Size Overlay
            if item.isVideo {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9))
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
        .cornerRadius(AppTheme.CornerRadius.small)
        .task {
            if image == nil {
                image = await MediaThumbnailService.shared.requestImage(for: item.asset)
            }
        }
    }
}
