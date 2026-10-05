import SwiftUI
import UIKit

public struct CategoryCard: View {
    public let category: MediaCategory
    public let itemCount: Int?
    public let formattedSize: String?
    public let action: () -> Void

    public init(category: MediaCategory, itemCount: Int? = nil, formattedSize: String? = nil, action: @escaping () -> Void) {
        self.category = category
        self.itemCount = itemCount
        self.formattedSize = formattedSize
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(category.themeColor.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: category.iconName)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(category.themeColor)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text(category.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(category.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: AppTheme.Spacing.xxs) {
                    if let size = formattedSize {
                        Text(size)
                            .font(.headline.weight(.bold))
                            .foregroundColor(category.themeColor)
                    } else if let count = itemCount {
                        Text("\(count)")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.primary)
                    } else {
                        ProgressView()
                            .scaleEffect(0.8)
                    }

                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
            }
            .padding(AppTheme.Spacing.md)
            .appCardStyle()
            .contentShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.title), \(itemCount != nil ? "\(itemCount!) items" : formattedSize ?? "")")
        .accessibilityAddTraits(.isButton)
    }
}
