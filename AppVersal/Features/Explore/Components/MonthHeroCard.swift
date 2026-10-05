//
//  MonthHeroCard.swift
//  AppVersal
//

import SwiftUI
import Photos

public struct MonthHeroCard: View {
    public let title: String
    public let itemCount: Int
    public let formattedSize: String
    public let previewAsset: PHAsset?
    public let action: () -> Void

    @State private var thumbnailImage: UIImage?

    public init(
        title: String,
        itemCount: Int,
        formattedSize: String,
        previewAsset: PHAsset? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.itemCount = itemCount
        self.formattedSize = formattedSize
        self.previewAsset = previewAsset
        self.action = action

        if let asset = previewAsset, let cached = HeroThumbnailCache.shared.image(for: asset.localIdentifier) {
            _thumbnailImage = State(initialValue: cached)
        } else {
            _thumbnailImage = State(initialValue: nil)
        }
    }

    public var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottom) {
                // Background Photo
                GeometryReader { geo in
                    if let img = thumbnailImage {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    } else {
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .overlay(
                            Image(systemName: "calendar")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.4))
                        )
                    }
                }

                // Dark Bottom Gradient Overlay
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.35), Color.black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 110)

                // Overlaid Details & Swipe Action Pill
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        Text("\(itemCount) \(itemCount == 1 ? "photo" : "photos") • \(formattedSize)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.85))
                    }

                    Spacer()

                    // Swipe Pill Button
                    HStack(spacing: 6) {
                        Image(systemName: "hand.draw.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("Swipe")
                            .font(.system(size: 14, weight: .bold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.24))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
            }
            .frame(height: 175)
            .cornerRadius(22)
            .shadow(color: Color.black.opacity(0.14), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
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
