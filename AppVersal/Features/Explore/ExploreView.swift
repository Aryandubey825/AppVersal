//
//  ExploreView.swift
//  AppVersal
//

import SwiftUI
import Combine

public struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.yearlyGroups.isEmpty {
                    VStack(spacing: AppTheme.Spacing.md) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading Years...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if viewModel.yearlyGroups.isEmpty {
                    EmptyStateView(
                        iconName: "calendar",
                        title: "No Media Found",
                        message: "Your photo gallery contains no active photos or videos."
                    )
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: AppTheme.Spacing.md) {
                            ForEach(viewModel.yearlyGroups) { group in
                                NavigationLink(destination: YearDetailView(year: group.year, exploreViewModel: viewModel)) {
                                    YearHeroCard(
                                        year: group.year,
                                        itemCount: group.items.count,
                                        formattedSize: group.formattedTotalSize,
                                        previewAsset: group.previewAsset
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(AppTheme.Spacing.md)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Explore")
            .onAppear {
                viewModel.loadYearlyGallery()
            }
        }
    }
}
