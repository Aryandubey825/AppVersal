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
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground).opacity(0.85))

            if let img = image {
                GeometryReader { geo in
                    ZStack {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .blur(radius: 28)
                            .opacity(0.35)
                            .clipped()

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
                        .tint(.primary)
                }
            }

            if isTopCard {
                HStack(spacing: 28) {
                    Button(role: .destructive) {
                        onTrashTap?()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 52, height: 52)

                            Image(systemName: "trash")
                                .font(.title3.weight(.bold))
                                .foregroundColor(.red)
                        }
                        .frame(width: 52, height: 52)
                        .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Move to Trash")
                    .scaleEffect(dragOffset.width < -20 ? 1.18 : 1.0)
                    .animation(.spring(response: 0.2), value: dragOffset.width)

                    Button {
                        onKeepTap?()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 52, height: 52)

                            Image(systemName: "suit.heart.fill")
                                .font(.title3.weight(.bold))
                                .foregroundColor(.mint)
                        }
                        .frame(width: 52, height: 52)
                        .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Keep photo")
                    .scaleEffect(dragOffset.width > 20 ? 1.18 : 1.0)
                    .animation(.spring(response: 0.2), value: dragOffset.width)
                }
                .padding(.top, 14)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: 7)
        .task(id: item.id) {
            await loadImage()
        }
    }

    private func loadImage() async {
        if let cached = HeroThumbnailCache.shared.image(for: item.id) {
            self.image = cached
        }

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
            guard let fullImg = fullImg else { return }
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            DispatchQueue.main.async {
                if !isDegraded {
                    self.image = fullImg
                } else if self.image == nil {
                    self.image = fullImg
                }
            }
        }
    }
}
