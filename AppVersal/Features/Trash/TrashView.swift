//
//  TrashView.swift
//  AppVersal
//

import SwiftUI
import Combine

public struct TrashView: View {
    @ObservedObject private var trashManager = TrashManager.shared
    @State private var selectedItemIds: Set<String> = []
    @State private var showEmptyTrashAlert: Bool = false
    @State private var isProcessing: Bool = false

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 160), spacing: 8)
    ]

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
                        // Summary Banner
                        headerBanner

                        // Trashed Media Grid
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(trashManager.trashedItems) { item in
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

                        // Bottom Actions Bar
                        bottomActionBar
                    }
                }
            }
            .navigationTitle("Trash (\(trashManager.trashedItems.count))")
            .toolbar {
                if !trashManager.trashedItems.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Empty All") {
                            showEmptyTrashAlert = true
                        }
                        .foregroundColor(.red)
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
                if selectedItemIds.count == trashManager.trashedItems.count {
                    selectedItemIds.removeAll()
                } else {
                    selectedItemIds = Set(trashManager.trashedItems.map { $0.id })
                }
            }
            .font(.subheadline.bold())
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }

    private var bottomActionBar: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Restore Button
            Button {
                let itemsToRestore = trashManager.trashedItems.filter { selectedItemIds.contains($0.id) }
                trashManager.restore(items: itemsToRestore.isEmpty ? trashManager.trashedItems : itemsToRestore)
                selectedItemIds.removeAll()
            } label: {
                HStack {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                    Text(selectedItemIds.isEmpty ? "Restore All" : "Restore (\(selectedItemIds.count))")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            // Permanent Delete Button
            Button(role: .destructive) {
                Task {
                    let itemsToDelete = trashManager.trashedItems.filter { selectedItemIds.contains($0.id) }
                    try? await trashManager.deletePermanently(items: itemsToDelete.isEmpty ? trashManager.trashedItems : itemsToDelete)
                    selectedItemIds.removeAll()
                }
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text(selectedItemIds.isEmpty ? "Delete All" : "Delete (\(selectedItemIds.count))")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color(UIColor.secondarySystemGroupedBackground))
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
