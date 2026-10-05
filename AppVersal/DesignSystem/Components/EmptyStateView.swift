import SwiftUI
import UIKit

public struct EmptyStateView: View {
    public let iconName: String
    public let title: String
    public let message: String

    public init(iconName: String = "checkmark.circle.fill", title: String, message: String) {
        self.iconName = iconName
        self.title = title
        self.message = message
    }

    public var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: iconName)
                    .font(.largeTitle)
                    .foregroundColor(.green)
            }

            Text(title)
                .font(.title2.bold())

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.lg)
        }
        .padding(AppTheme.Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}
