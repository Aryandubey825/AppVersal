import SwiftUI
import Photos

public struct SwAipeMonthStackCard: View {
    public let month: MonthGroup
    public let onOpen: (() -> Void)?

    @ObservedObject private var reviewManager = MonthReviewManager.shared
    @State private var thumbnailImage: UIImage?

    public init(month: MonthGroup, onOpen: (() -> Void)? = nil) {
        self.month = month
        self.onOpen = onOpen

        if let asset = month.previewAsset, let cached = HeroThumbnailCache.shared.image(for: asset.localIdentifier) {
            _thumbnailImage = State(initialValue: cached)
        } else {
            _thumbnailImage = State(initialValue: nil)
        }
    }

    private var stats: (swipedCount: Int, keptCount: Int, trashedCount: Int, percentage: Int, trashedBytes: Int64) {
        reviewManager.stats(for: month.id, totalItems: month.items.count)
    }

    private var trashedSizeText: String {
        stats.trashedBytes > 0 ? ByteFormatter.format(stats.trashedBytes) : "0 MB"
    }

    public var body: some View {
        Group {
            if let onOpen = onOpen {
                Button(action: onOpen) {
                    cardStackContent
                }
                .buttonStyle(.plain)
            } else {
                cardStackContent
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(month.monthName) gallery review, \(stats.swipedCount) of \(month.items.count) swiped, \(stats.percentage) percent done. \(stats.keptCount) kept, \(stats.trashedCount) trashed, \(trashedSizeText) reclaimed.")
        .accessibilityAddTraits(.isButton)
        .task(id: month.previewAsset?.localIdentifier) {
            await loadThumbnail()
        }
    }

    private var cardStackContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(month.monthName)
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Image(systemName: "chevron.right")
                    .font(.headline.bold())
                    .foregroundColor(.white.opacity(0.85))

                Spacer()
            }

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(UIColor.secondarySystemBackground).opacity(0.4))
                    .frame(height: 220)
                    .scaleEffect(0.90)
                    .offset(y: -14)

                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(UIColor.secondarySystemBackground).opacity(0.65))
                    .frame(height: 225)
                    .scaleEffect(0.95)
                    .offset(y: -7)

                mainCardFront
            }
            .frame(maxWidth: .infinity)
            .frame(height: 245)
            .padding(.top, 14)
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .contentShape(Rectangle())
    }

    private var mainCardFront: some View {
        ZStack(alignment: .bottom) {
            VStack {
                HStack {
                    Spacer()
                    progressBadge
                }
                .padding(.top, 14)
                .padding(.trailing, 14)

                Spacer()
            }
            .allowsHitTesting(false)

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.4), Color.black.opacity(0.88)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 110)
            .allowsHitTesting(false)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Swiped \(stats.swipedCount)/\(month.items.count)")
                        .font(.title3.bold())
                        .foregroundColor(.white)

                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "suit.heart.fill")
                                .font(.caption)
                            Text("\(stats.keptCount)")
                                .font(.subheadline.weight(.semibold))
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "trash.fill")
                                .font(.caption)
                            Text("\(stats.trashedCount)")
                                .font(.subheadline.weight(.semibold))
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "internaldrive.fill")
                                .font(.caption)
                            Text(trashedSizeText)
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .foregroundColor(.white.opacity(0.92))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white.opacity(0.95))
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 235)
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
                        colors: [Color.gray.opacity(0.6), Color.black.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.22), radius: 14, x: 0, y: 7)
    }

    private var progressBadge: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.55))
                .frame(width: 50, height: 50)

            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 4)
                .frame(width: 42, height: 42)

            Circle()
                .trim(from: 0, to: CGFloat(stats.percentage) / 100.0)
                .stroke(
                    Color.white,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 42, height: 42)
                .rotationEffect(.degrees(-90))

            Text("\(stats.percentage)%")
                .font(.caption.bold())
                .foregroundColor(.white)
        }
    }

    private func loadThumbnail() async {
        guard let asset = month.previewAsset else { return }
        if let cached = HeroThumbnailCache.shared.image(for: asset.localIdentifier) {
            self.thumbnailImage = cached
            return
        }
        if let img = await HeroThumbnailCache.shared.loadThumbnail(for: asset) {
            self.thumbnailImage = img
        }
    }
}
