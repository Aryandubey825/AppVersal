//
//  SimilarPhotosView.swift
//  AppVersal
//

import SwiftUI
import Combine

public struct SimilarPhotosView: View {
    @StateObject private var viewModel = SimilarPhotosViewModel()

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
                    ProgressHeader(title: "Analyzing Visual Similarity", processed: processed, total: total) {
                        viewModel.cancelAnalysis()
                    }
                    Spacer()
                }
                .padding()
            case .empty:
                EmptyStateView(
                    iconName: "photo.on.rectangle.angled",
                    title: "No Similar Photos",
                    message: "Your library looks clean and has no visually similar shots."
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
                                        Text("\(group.allItems.count) Similar Shots")
                                            .font(.headline)

                                        Spacer()

                                        Text("\(Int(group.averageSimilarityScore * 100))% match")
                                            .font(.caption.bold())
                                            .foregroundColor(.pink)
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
        .navigationTitle("Similar Photos")
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
                Task {
                    await viewModel.deleteSelected()
                }
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
