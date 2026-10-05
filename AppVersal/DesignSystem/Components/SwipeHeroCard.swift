//
//  SwipeHeroCard.swift
//  AppVersal
//

import SwiftUI
import UIKit
import Photos

public struct SwipeHeroCard: View {
    public let iconName: String
    public let accentColor: Color
    public let count: Int?
    public let formattedSize: String?
    public let title: String
    public let subtitle: String
    public let emptyTitle: String
    public let emptyMessage: String
    public let image: UIImage?
    public let action: () -> Void

    public init(
        iconName: String,
        accentColor: Color,
        count: Int?,
        formattedSize: String? = nil,
        title: String,
        subtitle: String,
        emptyTitle: String,
        emptyMessage: String,
        image: UIImage? = nil,
        action: @escaping () -> Void
    ) {
        self.iconName = iconName
        self.accentColor = accentColor
        self.count = count
        self.formattedSize = formattedSize
        self.title = title
        self.subtitle = subtitle
        self.emptyTitle = emptyTitle
        self.emptyMessage = emptyMessage
        self.image = image
        self.action = action
    }

    private var hasItems: Bool {
        if let count = count {
            return count > 0
        }
        if let size = formattedSize {
            return size != "0 B"
        }
        return false
    }

    private var countLabel: String {
        guard let count = count else { return subtitle }
        let singular: String
        let plural: String
        if title.localizedCaseInsensitiveContains("video") {
            singular = "video"
            plural = "videos"
        } else if title.localizedCaseInsensitiveContains("screenshot") {
            singular = "screenshot"
            plural = "screenshots"
        } else {
            singular = "photo"
            plural = "photos"
        }
        return "\(count) \(count == 1 ? singular : plural)"
    }

    public var body: some View {
        Button(action: action) {
            if hasItems {
                populatedHeroCard
            } else {
                emptyHeroCard
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Populated SwAipe-Style Hero Card (Zero-flicker Image Background)
    private var populatedHeroCard: some View {
        ZStack(alignment: .bottom) {
            // Full-bleed Image Background
            GeometryReader { geo in
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    // Stylized vibrant gradient background while image is requested
                    LinearGradient(
                        colors: [accentColor.opacity(0.85), accentColor.opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 44, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    )
                }
            }

            // Dark gradient overlay on bottom for high text contrast
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.35), Color.black.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 110)

            // Overlaid Content & Chevron (matching SwAipe app design)
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    if let size = formattedSize {
                        Text(size)
                            .font(.subheadline.bold())
                            .foregroundColor(.white.opacity(0.9))
                    } else {
                        Text(countLabel)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.85))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.trailing, 2)
                    .padding(.bottom, 2)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
        .frame(height: 195)
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.16), radius: 12, x: 0, y: 6)
    }

    // MARK: - Empty SwAipe-Style Card (Category SF Symbol, NO checkmark tick)
    private var emptyHeroCard: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 48, height: 48)

                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(emptyTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(emptyMessage)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
}
