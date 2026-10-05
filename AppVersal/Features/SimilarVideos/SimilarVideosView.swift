//
//  SimilarVideosView.swift
//  AppVersal
//

import SwiftUI
import Combine

public struct SimilarVideosView: View {
    @StateObject private var viewModel = SimilarVideosViewModel()

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
                    ProgressHeader(title: "Analyzing Similar Videos", processed: processed, total: total) {
                        viewModel.cancelAnalysis()
                    }
                    Spacer()
                }
                .padding()
            case .empty:
                EmptyStateView(
                    iconName: "film",
                    title: "No Similar Videos",
                    message: "Your library contains no visually or duration-similar video clips."
                )
            case .error(let msg):
                EmptyStateView(iconName: "exclamationmark.triangle.fill", title: "Error", message: msg)
            case .loaded(let groups):
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                            ForEach(groups) { group in
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
                        .padding(AppTheme.Spacing.md)
                    }

                    if !viewModel.selectedItemIds.isEmpty {
                        bottomDeleteBar
                    }
                }
            }
        }
        .navigationTitle("Similar Videos")
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
                Label("Move to Trash", systemImage: "trash.fill")
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
