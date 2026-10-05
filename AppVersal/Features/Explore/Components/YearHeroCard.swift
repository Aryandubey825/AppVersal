import SwiftUI
import UIKit
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
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.35), Color.black.opacity(0.88)],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(year))
                        .font(.title.bold())
                        .foregroundColor(.white)

                    Text("\(itemCount) \(itemCount == 1 ? "item" : "items") • \(formattedSize)")
                        .font(.subheadline.bold())
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.trailing, 2)
                    .padding(.bottom, 2)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 20)
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 185)
        .background {
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
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.16), radius: 12, x: 0, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(year), \(itemCount) items, \(formattedSize)")
        .accessibilityAddTraits(.isButton)
        .task(id: previewAsset?.localIdentifier) {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard let asset = previewAsset else { return }
        if let cached = HeroThumbnailCache.shared.image(for: asset.localIdentifier) {
            await MainActor.run {
                self.thumbnailImage = cached
            }
            return
        }

        let targetSize = CGSize(width: 600, height: 350)
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { [self] image, _ in
            if let img = image {
                Task { @MainActor in
                    self.thumbnailImage = img
                    HeroThumbnailCache.shared.setImage(img, for: asset.localIdentifier)
                }
            }
        }
    }
}
