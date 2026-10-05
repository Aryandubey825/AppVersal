//
//  ScreenshotsView.swift
//  AppVersal
//

import SwiftUI
import Combine

public struct ScreenshotsView: View {
    @StateObject private var viewModel = ScreenshotsViewModel()

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 160), spacing: 8)
    ]

    public init() {}

    public var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading Screenshots...")
            } else if viewModel.items.isEmpty {
                EmptyStateView(
                    iconName: "crop",
                    title: "No Screenshots",
                    message: "Your gallery doesn't contain any screenshots."
                )
            } else {
                VStack(spacing: 0) {
                    ScrollView {
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

                    if !viewModel.selectedItemIds.isEmpty {
                        bottomDeleteBar
                    }
                }
            }
        }
        .navigationTitle("Screenshots")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadScreenshots()
        }
    }

    private var bottomDeleteBar: some View {
        HStack {
            Text("\(viewModel.selectedItemIds.count) selected")
                .font(.headline)

            Spacer()

            Button(role: .destructive) {
                Task {
                    await viewModel.deleteSelected()
                }
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
