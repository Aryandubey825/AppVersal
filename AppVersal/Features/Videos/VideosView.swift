import SwiftUI
import Combine

public struct VideosView: View {
    @StateObject private var viewModel = VideosViewModel()
    @State private var showDeleteConfirmation: Bool = false

    private let columns = [
        GridItem(.adaptive(minimum: 110, maximum: 160), spacing: 8)
    ]

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            DateFilterBar(
                selectedFilter: $viewModel.selectedDateFilter,
                accentColor: MediaCategory.videos.themeColor
            )

            if viewModel.isLoading {
                ProgressView("Loading Videos...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.items.isEmpty {
                EmptyStateView(
                    iconName: "video.fill",
                    title: "No Videos",
                    message: "Your gallery doesn't contain any videos."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredItems.isEmpty {
                VStack(spacing: AppTheme.Spacing.md) {
                    EmptyStateView(
                        iconName: "calendar.badge.exclamationmark",
                        title: "No Videos Found",
                        message: "No videos found for \(viewModel.selectedDateFilter.title)."
                    )
                    Button("Reset Filter") {
                        viewModel.selectedDateFilter = .all
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(MediaCategory.videos.themeColor)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(AppTheme.Spacing.lg)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(viewModel.filteredItems) { item in
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
                            actionTitle: "Delete"
                        ) {
                            showDeleteConfirmation = true
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .animation(.snappy, value: viewModel.selectedItemIds.isEmpty)
        .sensoryFeedback(.selection, trigger: viewModel.selectedItemIds.count)
        .navigationTitle("Videos")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Move \(viewModel.selectedItemIds.count) videos to Trash?",
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
            viewModel.loadVideos()
        }
        .refreshable {
            viewModel.loadVideos()
        }
    }
}
