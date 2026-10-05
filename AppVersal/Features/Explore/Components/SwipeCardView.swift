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

    @State private var image: UIImage?

    public init(item: MediaItem, dragOffset: CGSize = .zero, isTopCard: Bool = true) {
        self.item = item
        self.dragOffset = dragOffset
        self.isTopCard = isTopCard
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Main Media Image
            GeometryReader { geo in
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    ZStack {
                        Color(UIColor.secondarySystemBackground)
                        ProgressView()
                            .tint(.white)
                    }
                }
            }

            // Dark Gradient Bottom Overlay
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.35), Color.black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)

            // Bottom Metadata Details
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    if let date = item.creationDate {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    HStack(spacing: 8) {
                        Text("\(item.pixelWidth) × \(item.pixelHeight)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))

                        if let size = item.fileSize, size > 0 {
                            Text("•")
                                .foregroundColor(.white.opacity(0.5))
                            Text(ByteFormatter.format(size))
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.95))
                        }

                        if item.isVideo {
                            Text("•")
                                .foregroundColor(.white.opacity(0.5))
                            Label(formatDuration(item.duration), systemImage: "video.fill")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            // Dynamic Apple HIG "KEEP" & "DELETE" Stamps
            if isTopCard {
                VStack {
                    HStack {
                        keepStamp
                            .opacity(keepOpacity)
                            .scaleEffect(keepOpacity > 0 ? 1.0 : 0.85)

                        Spacer()

                        trashStamp
                            .opacity(trashOpacity)
                            .scaleEffect(trashOpacity > 0 ? 1.0 : 0.85)
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 22)

                    Spacer()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 8)
        .task(id: item.id) {
            await loadImage()
        }
    }

    // MARK: - Apple HIG Keep Stamp (Frosted Glass + Green Accent)
    private var keepStamp: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .bold))
            Text("KEEP")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .foregroundColor(.green)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.green, lineWidth: 2)
        )
        .rotationEffect(.degrees(-8))
    }

    // MARK: - Apple HIG Delete Stamp (Frosted Glass + Red Accent)
    private var trashStamp: some View {
        HStack(spacing: 6) {
            Image(systemName: "trash.fill")
                .font(.system(size: 16, weight: .bold))
            Text("DELETE")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .foregroundColor(.red)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.red, lineWidth: 2)
        )
        .rotationEffect(.degrees(8))
    }

    private var keepOpacity: Double {
        guard dragOffset.width > 20 else { return 0 }
        return min(1.0, Double(dragOffset.width - 20) / 80.0)
    }

    private var trashOpacity: Double {
        guard dragOffset.width < -20 else { return 0 }
        return min(1.0, Double(-dragOffset.width - 20) / 80.0)
    }

    private func loadImage() async {
        if let cached = HeroThumbnailCache.shared.image(for: item.id) {
            self.image = cached
            return
        }

        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true

        let targetSize = CGSize(width: 800, height: 1200)

        PHImageManager.default().requestImage(
            for: item.asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { img, info in
            if let img = img {
                self.image = img
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded {
                    HeroThumbnailCache.shared.setImage(img, for: item.id)
                }
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
