import SwiftUI

public struct NativeDeleteBottomBar: View {
    public let selectedCount: Int
    public let actionTitle: String
    public let onDelete: () -> Void

    public init(
        selectedCount: Int,
        actionTitle: String = "Delete",
        onDelete: @escaping () -> Void
    ) {
        self.selectedCount = selectedCount
        self.actionTitle = actionTitle
        self.onDelete = onDelete
    }

    public var body: some View {
        HStack(spacing: 16) {
            Text("\(selectedCount) selected")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)

            Spacer()

            Button(role: .destructive, action: onDelete) {
                Label(actionTitle, systemImage: "trash")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(.red)
            .controlSize(.regular)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
