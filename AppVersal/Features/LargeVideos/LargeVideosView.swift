//
//  LargeVideosView.swift
//  AppVersal
//

import SwiftUI
import Combine

public struct LargeVideosView: View {
    @StateObject private var viewModel = LargeVideosViewModel()

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
                VStack(spacing: AppTheme.Spacing.lg) {
                    Spacer()
                    ProgressHeader(title: "Sorting Large Videos", processed: processed, total: total) {
                        viewModel.cancelAnalysis()
                    }
                    Spacer()
                }
                .padding()
            case .empty:
                EmptyStateView(
                    iconName: "arrow.up.left.and.arrow.down.right.circle.fill",
                    title: "No Videos",
                    message: "No video files found in your photo gallery."
                )
            case .error(let msg):
                EmptyStateView(iconName: "exclamationmark.triangle.fill", title: "Error", message: msg)
            case .loaded(let videos):
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(videos) { item in
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
        .navigationTitle("Large Videos")
        .navigationBarTitleDisplayMode(.inline)
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
                viewModel.deleteSelected()
            } label: {
                Label("Delete Selected", systemImage: "trash.fill")
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
