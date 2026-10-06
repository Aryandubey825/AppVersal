import SwiftUI
import Combine
import Photos

public struct TrashView: View {
    @ObservedObject private var trashManager = TrashManager.shared
    @State private var selectedItemIds: Set<String> = []
    @State private var isSelecting: Bool = false
    @State private var showEmptyTrashAlert: Bool = false
    @State private var showDeleteSelectedAlert: Bool = false
    @State private var isProcessing: Bool = false
    @State private var sortOption: TrashSortOption = .newest

    private enum TrashSortOption: String, CaseIterable, Identifiable {
        case newest = "Sort by Newest first"
        case oldest = "Sort by Oldest first"
        case recentlySwiped = "Sort by Recently Swiped"

        var id: String { rawValue }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    public init() {}

    private var sortedItems: [MediaItem] {
        switch sortOption {
        case .newest:
            return trashManager.trashedItems.sorted {
                ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast)
            }
        case .oldest:
            return trashManager.trashedItems.sorted {
                ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast)
            }
        case .recentlySwiped:
            return trashManager.trashedItems.reversed()
        }
    }

    private var selectedSizeFormatted: String {
        let selectedItems = trashManager.trashedItems.filter { selectedItemIds.contains($0.id) }
        let totalBytes = selectedItems.compactMap { $0.fileSize }.reduce(0, +)
        return ByteFormatter.format(totalBytes)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()

                if trashManager.trashedItems.isEmpty {
                    emptyStateView
                } else {
                    mainContentView
                }
            }
            .navigationTitle("Trash")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                toolbarContent
            }
            .alert("Empty Trash?", isPresented: $showEmptyTrashAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete All Permanently", role: .destructive) {
                    performEmptyTrash()
                }
            } message: {
                Text("This will permanently remove all \(trashManager.trashedItems.count) items from your device. This action cannot be undone.")
            }
            .confirmationDialog(
                selectedItemIds.count == 1
                    ? "Permanently delete 1 item?"
                    : "Permanently delete \(selectedItemIds.count) items?",
                isPresented: $showDeleteSelectedAlert,
                titleVisibility: .visible
            ) {
                Button("Delete Permanently", role: .destructive) {
                    performDeleteSelected()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("These items will be permanently erased from your device and cannot be recovered.")
            }
            .sensoryFeedback(.selection, trigger: selectedItemIds.count)
            .onAppear {
                trashManager.loadTrashedItems()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Spacer()

            Image(systemName: "trash")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(.secondary)
                .padding(.bottom, 4)

            Text("No Items in Trash")
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)

            Text("Photos and videos deleted from categories will appear here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var mainContentView: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(sortedItems) { item in
                    ThumbnailCell(
                        item: item,
                        isSelected: selectedItemIds.contains(item.id),
                        onSelectToggle: (isSelecting || !selectedItemIds.isEmpty) ? {
                            toggleSelection(id: item.id)
                        } : nil
                    )
                    .onTapGesture {
                        if !isSelecting && selectedItemIds.isEmpty {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isSelecting = true
                                selectedItemIds.insert(item.id)
                            }
                        } else {
                            toggleSelection(id: item.id)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            floatingCapsuleBar
        }
    }

    private var floatingCapsuleBar: some View {
        HStack(spacing: 0) {
            leftActionButton
                .frame(width: 44, height: 44)

            Spacer()

            VStack(spacing: 2) {
                if selectedItemIds.isEmpty {
                    Text("\(trashManager.trashedItems.count) items (\(ByteFormatter.format(trashManager.totalTrashSizeByte)))")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.primary)

                    Text("Select to Delete or Recover elements")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(selectedItemIds.count) of \(trashManager.trashedItems.count) selected (\(selectedSizeFormatted))")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.primary)

                    Text("Tap left to Recover, right to Delete")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .multilineTextAlignment(.center)

            Spacer()

            rightActionButton
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: 6)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedItemIds.count)
    }

    @ViewBuilder
    private var leftActionButton: some View {
        if selectedItemIds.isEmpty {
            Menu {
                Button("Sort by Newest first") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        sortOption = .newest
                    }
                }
                Button("Sort by Oldest first") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        sortOption = .oldest
                    }
                }
                Button("Sort by Recently Swiped") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        sortOption = .recentlySwiped
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.circle")
                    .font(.system(size: 26))
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                performRestoreSelected()
            } label: {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)
        }
    }

    @ViewBuilder
    private var rightActionButton: some View {
        if selectedItemIds.isEmpty {
            Menu {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isSelecting = true
                        selectedItemIds = Set(trashManager.trashedItems.map { $0.id })
                    }
                } label: {
                    Label("Select All", systemImage: "checkmark.circle")
                }

                Button {
                    performRestoreAll()
                } label: {
                    Label("Recover All", systemImage: "arrow.uturn.backward")
                }

                Divider()

                Button(role: .destructive) {
                    showEmptyTrashAlert = true
                } label: {
                    Label("Empty Trash", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 26))
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
        } else {
            Button(role: .destructive) {
                showDeleteSelectedAlert = true
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if !trashManager.trashedItems.isEmpty {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isSelecting || !selectedItemIds.isEmpty ? "Cancel" : "Select") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if isSelecting || !selectedItemIds.isEmpty {
                            selectedItemIds.removeAll()
                            isSelecting = false
                        } else {
                            isSelecting = true
                        }
                    }
                }
            }
        }
    }

    private func toggleSelection(id: String) {
        if selectedItemIds.contains(id) {
            selectedItemIds.remove(id)
            if selectedItemIds.isEmpty && !isSelecting {
                isSelecting = false
            }
        } else {
            selectedItemIds.insert(id)
        }
    }

    private func performRestoreSelected() {
        isProcessing = true
        let itemsToRestore = trashManager.trashedItems.filter { selectedItemIds.contains($0.id) }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            trashManager.restore(items: itemsToRestore)
            selectedItemIds.removeAll()
            isSelecting = false
            isProcessing = false
        }
    }

    private func performRestoreAll() {
        isProcessing = true
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            trashManager.restore(items: trashManager.trashedItems)
            selectedItemIds.removeAll()
            isSelecting = false
            isProcessing = false
        }
    }

    private func performDeleteSelected() {
        isProcessing = true
        let itemsToDelete = trashManager.trashedItems.filter { selectedItemIds.contains($0.id) }
        Task {
            try? await trashManager.deletePermanently(items: itemsToDelete)
            await MainActor.run {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    selectedItemIds.removeAll()
                    isSelecting = false
                    isProcessing = false
                }
            }
        }
    }

    private func performEmptyTrash() {
        isProcessing = true
        Task {
            try? await trashManager.emptyTrash()
            await MainActor.run {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    selectedItemIds.removeAll()
                    isSelecting = false
                    isProcessing = false
                }
            }
        }
    }
}
