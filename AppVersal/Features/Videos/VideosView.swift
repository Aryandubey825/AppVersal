//
//  VideosView.swift
//  AppVersal
//

import SwiftUI
import Combine

public struct VideosView: View {
    @StateObject private var viewModel = VideosViewModel()

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
                VStack(spacing: 0) {
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

                    if !viewModel.selectedItemIds.isEmpty {
                        bottomDeleteBar
                    }
                }
            }
        }
        .navigationTitle("Videos")
        .navigationBarTitleDisplayMode(.inline)
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
                viewModel.deleteSelected()
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
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
}
