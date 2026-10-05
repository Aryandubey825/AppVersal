import SwiftUI
import UIKit

public struct ProgressHeader: View {
    public let title: String
    public let processed: Int
    public let total: Int
    public let onCancel: (() -> Void)?

    public init(title: String, processed: Int, total: Int, onCancel: (() -> Void)? = nil) {
        self.title = title
        self.processed = processed
        self.total = total
        self.onCancel = onCancel
    }

    private var ratio: Double {
        guard total > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(processed) / Double(total)))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                        .symbolEffect(.pulse)

                    Text(title)
                        .font(.headline)
                }

                Spacer()

                if let cancel = onCancel {
                    Button("Cancel", action: cancel)
                        .font(.subheadline.bold())
                        .foregroundColor(.red)
                }
            }

            ProgressView(value: ratio)
                .tint(.blue)

            HStack {
                Text("\(processed) / \(total) items analyzed")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(ratio * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
        }
        .padding(AppTheme.Spacing.md)
        .appCardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(processed) of \(total) items analyzed, \(Int(ratio * 100)) percent")
    }
}
