import SwiftUI
import Combine

public struct ScreenshotsView: View {
    @StateObject private var viewModel = ScreenshotsViewModel()
    @State private var showDeleteConfirmation: Bool = false

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 160), spacing: 8)
    ]

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            DateFilterBar(
                selectedFilter: $viewModel.selectedDateFilter,
                accentColor: MediaCategory.screenshots.themeColor
            )

            if viewModel.isLoading {
                ProgressView("Loading Screenshots...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.items.isEmpty {
                EmptyStateView(
                    iconName: "crop",
                    title: "No Screenshots",
                    message: "Your gallery doesn't contain any screenshots."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredItems.isEmpty {
                VStack(spacing: AppTheme.Spacing.md) {
                    EmptyStateView(
                        iconName: "calendar.badge.exclamationmark",
                        title: "No Screenshots Found",
                        message: "No screenshots found for \(viewModel.selectedDateFilter.title)."
                    )
                    Button("Reset Filter") {
                        viewModel.selectedDateFilter = .all
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(MediaCategory.screenshots.themeColor)
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
        .navigationTitle("Screenshots")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Move \(viewModel.selectedItemIds.count) screenshots to Trash?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive) {
                viewModel.deleteSelected()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("These screenshots will be moved to the in-app Trash where you can restore them anytime.")
        }
        .onAppear {
            viewModel.loadScreenshots()
        }
        .refreshable {
            viewModel.loadScreenshots()
        }
    }
}
