import SwiftUI
import Combine

public struct DuplicatePhotosView: View {
    @StateObject private var viewModel = DuplicatePhotosViewModel()
    @State private var showDeleteConfirmation: Bool = false

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 160), spacing: 8)
    ]

    public init() {}

    public var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                Color.clear
            case .loading(let processed, let total):
                VStack(spacing: AppTheme.Spacing.lg) {
                    Spacer()
                    ProgressHeader(title: "Analyzing Duplicate Photos", processed: processed, total: total) {
                        viewModel.cancelAnalysis()
                    }
                    Spacer()
                }
                .padding()
            case .empty:
                EmptyStateView(
                    iconName: "doc.on.doc.fill",
                    title: "No Duplicates Found",
                    message: "Your photo gallery contains no exact duplicate photos."
                )
            case .error(let msg):
                EmptyStateView(iconName: "exclamationmark.triangle.fill", title: "Error", message: msg)
            case .loaded(let groups):
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        ForEach(groups) { group in
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                HStack {
                                    Text("\(group.items.count) Exact Copies")
                                        .font(.headline)

                                    Spacer()

                                    Text(ByteFormatter.format(group.reclaimableSizeByte) + " reclaimable")
                                        .font(.caption.bold())
                                        .foregroundColor(.orange)
                                }
                                .padding(.horizontal, 4)

                                LazyVGrid(columns: columns, spacing: 8) {
                                    ForEach(group.items) { item in
                                        ThumbnailCell(
                                            item: item,
                                            isSelected: viewModel.selectedItemIds.contains(item.id)
                                        ) {
                                            viewModel.toggleSelection(id: item.id)
                                        }
                                    }
                                }
                            }
                            .padding(AppTheme.Spacing.md)
                            .appCardStyle()
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
                .safeAreaInset(edge: .bottom) {
                    if !viewModel.selectedItemIds.isEmpty {
                        bottomDeleteBar
                            .background(.ultraThinMaterial)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .animation(.snappy, value: viewModel.selectedItemIds.isEmpty)
        .sensoryFeedback(.selection, trigger: viewModel.selectedItemIds.count)
        .navigationTitle("Duplicate Photos")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Move \(viewModel.selectedItemIds.count) duplicate photos to Trash?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive) {
                viewModel.deleteSelected()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("These duplicate copies will be moved to the in-app Trash where you can restore them anytime.")
        }
        .onAppear {
            viewModel.startAnalysis()
        }
    }

    private var bottomDeleteBar: some View {
        HStack {
            Text("\(viewModel.selectedItemIds.count) selected")
                .font(.headline)

            Spacer()

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete Duplicates", systemImage: "trash.fill")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}
