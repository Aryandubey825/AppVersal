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
    public let action: (() -> Void)?

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
        action: (() -> Void)? = nil
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
        Group {
            if let action = action {
                Button(action: action) {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(hasItems ? "\(title), \(formattedSize ?? countLabel)" : "\(emptyTitle), \(emptyMessage)")
        .accessibilityAddTraits(.isButton)
    }

    private var cardContent: some View {
        Group {
            if hasItems {
                populatedHeroCard
            } else {
                emptyHeroCard
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var populatedHeroCard: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.35), Color.black.opacity(0.88)],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

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
                            .font(.subheadline.bold())
                            .foregroundColor(.white.opacity(0.85))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.trailing, 2)
                    .padding(.bottom, 2)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 195)
        .background {
            GeometryReader { geo in
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
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
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.16), radius: 12, x: 0, y: 6)
    }

    private var emptyHeroCard: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 48, height: 48)

                Image(systemName: iconName)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(emptyTitle)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(emptyMessage)
                    .font(.footnote)
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
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
