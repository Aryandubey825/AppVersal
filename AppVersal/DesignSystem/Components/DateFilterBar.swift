import SwiftUI

public struct DateFilterBar: View {
    @Binding public var selectedFilter: DateFilterOption
    public let accentColor: Color

    @State private var showCustomSheet: Bool = false

    public init(selectedFilter: Binding<DateFilterOption>, accentColor: Color = .blue) {
        self._selectedFilter = selectedFilter
        self.accentColor = accentColor
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DateFilterOption.standardPresets, id: \.self) { option in
                    chipButton(
                        title: option.title,
                        isSelected: selectedFilter == option
                    ) {
                        selectedFilter = option
                    }
                }

                customChip
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, 8)
        }
        .frame(height: 52)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color(UIColor.systemBackground))
        .sensoryFeedback(.selection, trigger: selectedFilter)
        .sheet(isPresented: $showCustomSheet) {
            DateFilterSheet(
                selectedFilter: $selectedFilter,
                accentColor: accentColor
            )
        }
    }

    private func chipButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(minHeight: 36)
                .background(isSelected ? accentColor : Color(UIColor.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : Color(UIColor.separator).opacity(0.6), lineWidth: 1)
                )
                .shadow(color: isSelected ? accentColor.opacity(0.35) : Color.clear, radius: 4, x: 0, y: 2)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var customChip: some View {
        HStack(spacing: 6) {
            Button {
                showCustomSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(isCustomActive ? .white : accentColor)

                    Text(isCustomActive ? selectedFilter.shortTitle : "Custom")
                        .font(.subheadline.weight(isCustomActive ? .semibold : .medium))
                        .foregroundColor(isCustomActive ? .white : .primary)
                }
            }
            .buttonStyle(.plain)

            if isCustomActive {
                Button {
                    selectedFilter = .all
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(minHeight: 36)
        .background(isCustomActive ? accentColor : Color(UIColor.systemGray5))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(isCustomActive ? Color.clear : Color(UIColor.separator).opacity(0.6), lineWidth: 1)
        )
        .shadow(color: isCustomActive ? accentColor.opacity(0.35) : Color.clear, radius: 4, x: 0, y: 2)
    }

    private var isCustomActive: Bool {
        if case .custom = selectedFilter {
            return true
        }
        return false
    }
}
