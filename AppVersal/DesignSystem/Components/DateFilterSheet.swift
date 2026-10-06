import SwiftUI

public struct DateFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding public var selectedFilter: DateFilterOption
    public let accentColor: Color

    @State private var startDate: Date
    @State private var endDate: Date

    public init(selectedFilter: Binding<DateFilterOption>, accentColor: Color = .blue) {
        self._selectedFilter = selectedFilter
        self.accentColor = accentColor

        let initialStart: Date
        let initialEnd: Date
        if case .custom(let start, let end) = selectedFilter.wrappedValue {
            initialStart = start
            initialEnd = end
        } else {
            let cal = Calendar.current
            initialEnd = Date()
            initialStart = cal.date(byAdding: .month, value: -1, to: initialEnd) ?? initialEnd
        }

        self._startDate = State(initialValue: initialStart)
        self._endDate = State(initialValue: initialEnd)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Quick Presets") {
                    ForEach(DateFilterOption.standardPresets, id: \.self) { preset in
                        Button {
                            selectedFilter = preset
                            dismiss()
                        } label: {
                            HStack {
                                Text(preset.title)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedFilter == preset {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(accentColor)
                                        .font(.subheadline.bold())
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .frame(minHeight: 44)
                    }
                }

                Section("Custom Date Range") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
                    DatePicker("End Date", selection: $endDate, displayedComponents: [.date])

                    Button {
                        selectedFilter = .custom(start: startDate, end: endDate)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Apply Custom Range")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(accentColor)
                        .cornerRadius(AppTheme.CornerRadius.small)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }

                if selectedFilter.isFiltered {
                    Section {
                        Button(role: .destructive) {
                            selectedFilter = .all
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Reset to All Time")
                                    .font(.headline)
                                Spacer()
                            }
                        }
                        .frame(minHeight: 44)
                    }
                }
            }
            .navigationTitle("Filter by Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
