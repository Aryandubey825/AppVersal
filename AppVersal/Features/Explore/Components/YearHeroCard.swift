//
//  YearHeroCard.swift
//  AppVersal
//

import SwiftUI
import Photos

public struct YearHeroCard: View {
    public let year: Int
    public let itemCount: Int
    public let formattedSize: String
    public let previewAsset: PHAsset?

    @State private var thumbnailImage: UIImage?

    public init(
        year: Int,
        itemCount: Int,
        formattedSize: String,
        previewAsset: PHAsset? = nil
    ) {
        self.year = year
        self.itemCount = itemCount
        self.formattedSize = formattedSize
        self.previewAsset = previewAsset

        if let asset = previewAsset, let cached = HeroThumbnailCache.shared.image(for: asset.localIdentifier) {
            _thumbnailImage = State(initialValue: cached)
        } else {
            _thumbnailImage = State(initialValue: nil)
        }
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Full-bleed Image Background
            GeometryReader { geo in
                if let img = thumbnailImage {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: [Color.blue.opacity(0.85), Color.purple.opacity(0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        Image(systemName: "calendar")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    )
                }
            }

            // Dark bottom gradient overlay
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.35), Color.black.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 110)

            // Overlaid Content & Chevron
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(year))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("\(itemCount) \(itemCount == 1 ? "item" : "items") • \(formattedSize)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.88))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.trailing, 2)
                    .padding(.bottom, 2)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 20)
        }
        .frame(height: 185)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.16), radius: 12, x: 0, y: 6)
        .task(id: previewAsset?.localIdentifier) {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard let asset = previewAsset else { return }
        if let cached = HeroThumbnailCache.shared.image(for: asset.localIdentifier) {
            self.thumbnailImage = cached
            return
        }
        if let img = await HeroThumbnailCache.shared.loadThumbnail(for: asset) {
            self.thumbnailImage = img
        }
    }
}
