//
//  SwAipeMonthStackCard.swift
//  AppVersal
//

import SwiftUI
import Photos

public struct SwAipeMonthStackCard: View {
    public let month: MonthGroup
    public let onOpen: () -> Void

    @ObservedObject private var reviewManager = MonthReviewManager.shared
    @State private var thumbnailImage: UIImage?

    public init(month: MonthGroup, onOpen: @escaping () -> Void) {
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
        VStack(alignment: .leading, spacing: 14) {
            // Month Header (e.g. "February >")
            Button(action: onOpen) {
                HStack(spacing: 8) {
                    Text(month.monthName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            // Card Deck Stack (matching SwAipe app screenshot)
            Button(action: onOpen) {
                ZStack(alignment: .bottom) {
                    // Layer 3: Farthest Background Card
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(UIColor.secondarySystemBackground).opacity(0.4))
                        .frame(height: 220)
                        .scaleEffect(0.90)
                        .offset(y: -14)

                    // Layer 2: Middle Background Card
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(UIColor.secondarySystemBackground).opacity(0.65))
                        .frame(height: 225)
                        .scaleEffect(0.95)
                        .offset(y: -7)

                    // Layer 1: Front / Main Photo Card
                    mainCardFront
                        .frame(height: 235)
                }
            }
            .buttonStyle(.plain)
        }
        .task(id: month.previewAsset?.localIdentifier) {
            await loadThumbnail()
        }
    }

    // MARK: - Front Main Card
    private var mainCardFront: some View {
        ZStack(alignment: .bottom) {
            // Photo Image
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

            // Top-Right Circular Progress Badge (e.g. "0%")
            VStack {
                HStack {
                    Spacer()
                    progressBadge
                }
                .padding(.top, 14)
                .padding(.trailing, 14)

                Spacer()
            }

            // Bottom Dark Gradient Overlay
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.4), Color.black.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)

            // Bottom Stats Row & Chevron
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 5) {
                    // "Swiped 0/4"
                    Text("Swiped \(stats.swipedCount)/\(month.items.count)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    // Metrics: Heart, Trash, Drive
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "suit.heart.fill")
                                .font(.system(size: 13))
                            Text("\(stats.keptCount)")
                                .font(.system(size: 14, weight: .semibold))
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 13))
                            Text("\(stats.trashedCount)")
                                .font(.system(size: 14, weight: .semibold))
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "internaldrive.fill")
                                .font(.system(size: 13))
                            Text(trashedSizeText)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white.opacity(0.92))
                }

                Spacer()

                // Inside Right Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white.opacity(0.95))
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.22), radius: 14, x: 0, y: 7)
    }

    // MARK: - Circular Progress Badge (e.g. "0%")
    private var progressBadge: some View {
        ZStack {
            // Dark circular background
            Circle()
                .fill(Color.black.opacity(0.55))
                .frame(width: 50, height: 50)

            // Inactive Track
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 4)
                .frame(width: 42, height: 42)

            // Active Progress Trim
            Circle()
                .trim(from: 0, to: CGFloat(stats.percentage) / 100.0)
                .stroke(
                    Color.white,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 42, height: 42)
                .rotationEffect(.degrees(-90))

            // Percentage Text
            Text("\(stats.percentage)%")
                .font(.system(size: 13, weight: .bold))
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
