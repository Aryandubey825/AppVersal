import SwiftUI
import Combine

public struct SimilarVideosView: View {
    @StateObject private var viewModel = SimilarVideosViewModel()
    @State private var showDeleteConfirmation: Bool = false

    private let columns = [
        GridItem(.adaptive(minimum: 110, maximum: 160), spacing: 8)
    ]

    public init() {}

    public var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                Color.clear
            case .loading(let processed, let total):
                ProgressHeader(title: "Analyzing Similar Videos", processed: processed, total: total) {
                    viewModel.cancelAnalysis()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            case .empty:
                EmptyStateView(
                    iconName: "film",
                    title: "No Similar Videos",
                    message: "Your library contains no visually or duration-similar video clips."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let msg):
                EmptyStateView(iconName: "exclamationmark.triangle.fill", title: "Error", message: msg)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                VStack(spacing: 0) {
                    DateFilterBar(
                        selectedFilter: $viewModel.selectedDateFilter,
                        accentColor: MediaCategory.similarVideos.themeColor
                    )

                    if viewModel.filteredGroups.isEmpty {
                        VStack(spacing: AppTheme.Spacing.md) {
                            EmptyStateView(
                                iconName: "calendar.badge.exclamationmark",
                                title: "No Similar Videos Found",
                                message: "No visually similar videos found for \(viewModel.selectedDateFilter.title)."
                            )
                            Button("Reset Filter") {
                                viewModel.selectedDateFilter = .all
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(MediaCategory.similarVideos.themeColor)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(AppTheme.Spacing.lg)
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                                ForEach(viewModel.filteredGroups) { group in
                                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                        HStack {
                                            Text("\(group.allItems.count) Similar Videos")
                                                .font(.headline)

                                            Spacer()

                                            Text("\(Int(group.averageSimilarityScore * 100))% match")
                                                .font(.caption.bold())
                                                .foregroundColor(.teal)
                                        }
                                        .padding(.horizontal, 4)

                                        LazyVGrid(columns: columns, spacing: 8) {
                                            ForEach(group.allItems) { item in
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
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.top, 4)
                            .padding(.bottom, AppTheme.Spacing.lg)
                        }
                        .scrollIndicators(.hidden)
                        .scrollBounceBehavior(.basedOnSize)
                        .safeAreaInset(edge: .bottom) {
                            if !viewModel.selectedItemIds.isEmpty {
                                NativeDeleteBottomBar(
                                    selectedCount: viewModel.selectedItemIds.count,
                                    actionTitle: "Move to Trash"
                                ) {
                                    showDeleteConfirmation = true
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                    }
                }
            }
        }
        .animation(.snappy, value: viewModel.selectedItemIds.isEmpty)
        .sensoryFeedback(.selection, trigger: viewModel.selectedItemIds.count)
        .navigationTitle("Similar Videos")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Move \(viewModel.selectedItemIds.count) similar videos to Trash?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive) {
                viewModel.deleteSelected()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("These videos will be moved to the in-app Trash where you can restore them anytime.")
        }
        .onAppear {
            viewModel.startAnalysis()
        }
    }
}
