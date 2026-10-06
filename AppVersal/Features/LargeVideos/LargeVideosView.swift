import SwiftUI
import Combine

public struct LargeVideosView: View {
    @StateObject private var viewModel = LargeVideosViewModel()
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
                ProgressHeader(title: "Sorting Large Videos", processed: processed, total: total) {
                    viewModel.cancelAnalysis()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            case .empty:
                EmptyStateView(
                    iconName: "arrow.up.left.and.arrow.down.right.circle.fill",
                    title: "No Videos",
                    message: "No video files found in your photo gallery."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let msg):
                EmptyStateView(iconName: "exclamationmark.triangle.fill", title: "Error", message: msg)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                VStack(spacing: 0) {
                    DateFilterBar(
                        selectedFilter: $viewModel.selectedDateFilter,
                        accentColor: MediaCategory.largeVideos.themeColor
                    )

                    if viewModel.filteredVideos.isEmpty {
                        VStack(spacing: AppTheme.Spacing.md) {
                            EmptyStateView(
                                iconName: "calendar.badge.exclamationmark",
                                title: "No Large Videos Found",
                                message: "No large videos found for \(viewModel.selectedDateFilter.title)."
                            )
                            Button("Reset Filter") {
                                viewModel.selectedDateFilter = .all
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(MediaCategory.largeVideos.themeColor)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(AppTheme.Spacing.lg)
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(viewModel.filteredVideos) { item in
                                    ThumbnailCell(
                                        item: item,
                                        isSelected: viewModel.selectedItemIds.contains(item.id)
                                    ) {
                                        viewModel.toggleSelection(id: item.id)
                                    }
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
                                    actionTitle: "Delete Selected"
                                ) {
                                    showDeleteConfirmation = true
                                }
                                .confirmationDialog(
                                    viewModel.selectedItemIds.count == 1 ? "Move 1 large video to Trash?" : "Move \(viewModel.selectedItemIds.count) large videos to Trash?",
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
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                    }
                }
            }
        }
        .animation(.snappy, value: viewModel.selectedItemIds.isEmpty)
        .sensoryFeedback(.selection, trigger: viewModel.selectedItemIds.count)
        .navigationTitle("Large Videos")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if case .idle = viewModel.state {
                viewModel.startAnalysis()
            }
        }
    }
}
