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
        Group {
            if viewModel.isLoading {
                ProgressView("Loading Videos...")
            } else if viewModel.items.isEmpty {
                EmptyStateView(
                    iconName: "video.fill",
                    title: "No Videos",
                    message: "Your gallery doesn't contain any videos."
                )
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(viewModel.items) { item in
                            ThumbnailCell(
                                item: item,
                                isSelected: viewModel.selectedItemIds.contains(item.id)
                            ) {
                                viewModel.toggleSelection(id: item.id)
                            }
                        }
                    }
                    .padding(12)
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

    private var bottomDeleteBar: some View {
        HStack {
            Text("\(viewModel.selectedItemIds.count) selected")
                .font(.headline)

            Spacer()

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash.fill")
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
