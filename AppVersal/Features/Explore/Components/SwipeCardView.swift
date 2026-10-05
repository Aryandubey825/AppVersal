//
//  SwipeCardView.swift
//  AppVersal
//

import SwiftUI
import Photos

public struct SwipeCardView: View {
    public let item: MediaItem
    public let dragOffset: CGSize
    public let isTopCard: Bool
    public var onTrashTap: (() -> Void)? = nil
    public var onKeepTap: (() -> Void)? = nil

    @State private var image: UIImage?

    public init(
        item: MediaItem,
        dragOffset: CGSize = .zero,
        isTopCard: Bool = true,
        onTrashTap: (() -> Void)? = nil,
        onKeepTap: (() -> Void)? = nil
    ) {
        self.item = item
        self.dragOffset = dragOffset
        self.isTopCard = isTopCard
        self.onTrashTap = onTrashTap
        self.onKeepTap = onKeepTap
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // Card Container
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground).opacity(0.85))

            if let img = image {
                GeometryReader { geo in
                    ZStack {
                        // Soft Ambient Blurred Backdrop (photo colors fill empty space for wide images)
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .blur(radius: 28)
                            .opacity(0.35)
                            .clipped()

                        // 100% Uncut Full Photo (never cropped, never distorted)
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    }
                }
            } else {
                ZStack {
                    Color(UIColor.secondarySystemBackground)
                    ProgressView()
                        .tint(.white)
                }
            }

            // Top Quick Action Badges (Trash & Heart) on Front Card
            if isTopCard {
                HStack(spacing: 28) {
                    // Trash Badge Button
                    Button {
                        onTrashTap?()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 48, height: 48)

                            Image(systemName: "trash.fill")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundColor(Color(red: 1.0, green: 0.45, blue: 0.5))
                        }
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(dragOffset.width < -20 ? 1.18 : 1.0)
                    .animation(.spring(response: 0.2), value: dragOffset.width)

                    // Heart / Keep Badge Button
                    Button {
                        onKeepTap?()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 48, height: 48)

                            Image(systemName: "suit.heart.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(red: 0.45, green: 0.85, blue: 0.72))
                        }
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(dragOffset.width > 20 ? 1.18 : 1.0)
                    .animation(.spring(response: 0.2), value: dragOffset.width)
                }
                .padding(.top, 14)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.24), radius: 16, x: 0, y: 8)
        .task(id: item.id) {
            await loadImage()
        }
    }

    private func loadImage() async {
        // Show cached low-res thumbnail immediately if available
        if let cached = HeroThumbnailCache.shared.image(for: item.id) {
            self.image = cached
        }

        // Always request crisp, high-resolution original image so it never pixelates
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true

        let targetWidth = max(item.pixelWidth, 1200)
        let targetHeight = max(item.pixelHeight, 1800)
        let targetSize = CGSize(width: targetWidth, height: targetHeight)

        PHImageManager.default().requestImage(
            for: item.asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { fullImg, info in
            if let fullImg = fullImg {
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded {
                    self.image = fullImg
                } else if self.image == nil {
                    self.image = fullImg
                }
            }
        }
    }
}
