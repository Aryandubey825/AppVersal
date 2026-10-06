import SwiftUI
import Combine

public struct TrashView: View {
    @ObservedObject private var trashManager = TrashManager.shared
    @State private var selectedItemIds: Set<String> = []
    @State private var showEmptyTrashAlert: Bool = false
    @State private var isProcessing: Bool = false
    @State private var selectedDateFilter: DateFilterOption = .all

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 160), spacing: 8)
    ]

    private var filteredItems: [MediaItem] {
        guard selectedDateFilter.isFiltered else { return trashManager.trashedItems }
        return trashManager.trashedItems.filter { selectedDateFilter.matches(date: $0.creationDate) }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if trashManager.trashedItems.isEmpty {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        EmptyStateView(
                            iconName: "trash.slash.fill",
                            title: "Trash is Empty",
                            message: "Photos and videos deleted from categories will appear here."
                        )
                        recentlyDeletedInfoCard
                            .padding(.horizontal, AppTheme.Spacing.md)
                    }
                } else {
                    VStack(spacing: 0) {
                        headerBanner

                        DateFilterBar(
                            selectedFilter: $selectedDateFilter,
                            accentColor: .red
                        )

                        if filteredItems.isEmpty {
                            VStack(spacing: AppTheme.Spacing.md) {
                                Spacer()
                                EmptyStateView(
                                    iconName: "calendar.badge.exclamationmark",
                                    title: "No Trashed Items Found",
                                    message: "No trashed items found for \(selectedDateFilter.title)."
                                )
                                Button("Reset Filter") {
                                    selectedDateFilter = .all
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                                Spacer()
                            }
                        } else {
                            ScrollView(showsIndicators: false) {
                                LazyVGrid(columns: columns, spacing: 8) {
                                    ForEach(filteredItems) { item in
                                        ThumbnailCell(
                                            item: item,
                                            isSelected: selectedItemIds.contains(item.id)
                                        ) {
                                            toggleSelection(id: item.id)
                                        }
                                    }
                                }
                                .padding(AppTheme.Spacing.md)
                            }
                            .scrollIndicators(.hidden)
                            .scrollBounceBehavior(.basedOnSize)
                            .safeAreaInset(edge: .bottom) {
                                bottomActionBar
                            }
                        }
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: selectedItemIds.count)
            .navigationTitle("Trash (\(trashManager.trashedItems.count))")
            .toolbar {
                if !trashManager.trashedItems.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(role: .destructive) {
                            showEmptyTrashAlert = true
                        } label: {
                            Text("Empty All")
                                .font(.subheadline.bold())
                        }
                        .tint(.red)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                }
            }
            .alert("Empty Trash?", isPresented: $showEmptyTrashAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete All Permanently", role: .destructive) {
                    Task {
                        try? await trashManager.emptyTrash()
                        selectedItemIds.removeAll()
                    }
                }
            } message: {
                Text("This will permanently remove all \(trashManager.trashedItems.count) items from your device.")
            }
            .onAppear {
                trashManager.loadTrashedItems()
            }
        }
    }

    private var headerBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(trashManager.trashedItems.count) Items in Trash")
                    .font(.headline)
                Text(ByteFormatter.format(trashManager.totalTrashSizeByte) + " reclaimable")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
            }

            Spacer()

            Button("Select All") {
                if selectedItemIds.count == filteredItems.count {
                    selectedItemIds.removeAll()
                } else {
                    selectedItemIds = Set(filteredItems.map { $0.id })
                }
            }
            .font(.subheadline.bold())
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }

    private var bottomActionBar: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Button {
                let itemsToRestore = trashManager.trashedItems.filter { selectedItemIds.contains($0.id) }
                trashManager.restore(items: itemsToRestore.isEmpty ? filteredItems : itemsToRestore)
                selectedItemIds.removeAll()
            } label: {
                Label(selectedItemIds.isEmpty ? "Restore All" : "Restore (\(selectedItemIds.count))", systemImage: "arrow.uturn.backward.circle")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(.blue)

            Button(role: .destructive) {
                Task {
                    let itemsToDelete = trashManager.trashedItems.filter { selectedItemIds.contains($0.id) }
                    try? await trashManager.deletePermanently(items: itemsToDelete.isEmpty ? filteredItems : itemsToDelete)
                    selectedItemIds.removeAll()
                }
            } label: {
                Label(selectedItemIds.isEmpty ? "Delete All" : "Delete (\(selectedItemIds.count))", systemImage: "trash")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(.red)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var recentlyDeletedInfoCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("How Trash Works")
                    .font(.headline)
            }

            Text("Items you move to Trash can be restored anytime or permanently deleted to free up storage.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(AppTheme.Spacing.md)
        .appCardStyle()
    }

    private func toggleSelection(id: String) {
        if selectedItemIds.contains(id) {
            selectedItemIds.remove(id)
        } else {
            selectedItemIds.insert(id)
        }
    }
}
