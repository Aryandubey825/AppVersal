//
//  HomeView.swift
//  AppVersal
//

import SwiftUI
import Combine

public struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedCategory: MediaCategory? = nil

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    // Top: Real iPhone Storage Card (used vs free space)
                    DeviceStorageCard(
                        usedBytes: viewModel.usedDeviceStorage,
                        totalBytes: viewModel.totalDeviceStorage,
                        freeBytes: viewModel.freeDeviceStorage,
                        usedRatio: viewModel.storageUsedRatio
                    )

                    // 1. Screenshots & Videos Section
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Media")
                            .font(.title3.bold())
                            .padding(.horizontal, AppTheme.Spacing.xs)

                        VStack(spacing: AppTheme.Spacing.sm) {
                            SwipeHeroCard(
                                iconName: MediaCategory.screenshots.iconName,
                                accentColor: MediaCategory.screenshots.themeColor,
                                count: viewModel.categoryCounts[.screenshots],
                                title: "Screenshots",
                                subtitle: "Clean up unwanted screen captures",
                                emptyTitle: "No Screenshots",
                                emptyMessage: "We will automatically find new screenshots if you take more.",
                                image: viewModel.previewImages[.screenshots]
                            ) {
                                selectedCategory = .screenshots
                            }

                            SwipeHeroCard(
                                iconName: MediaCategory.videos.iconName,
                                accentColor: MediaCategory.videos.themeColor,
                                count: viewModel.categoryCounts[.videos],
                                title: "Videos",
                                subtitle: "Browse and manage all recorded videos",
                                emptyTitle: "No Videos",
                                emptyMessage: "No video files found in your gallery.",
                                image: viewModel.previewImages[.videos]
                            ) {
                                selectedCategory = .videos
                            }
                        }
                    }

                    // 2. Similars Section (Photos & Videos)
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Similars")
                            .font(.title3.bold())
                            .padding(.horizontal, AppTheme.Spacing.xs)

                        VStack(spacing: AppTheme.Spacing.sm) {
                            // Similar Photos Card
                            SwipeHeroCard(
                                iconName: MediaCategory.similarPhotos.iconName,
                                accentColor: MediaCategory.similarPhotos.themeColor,
                                count: viewModel.categoryCounts[.similarPhotos],
                                title: "Photos",
                                subtitle: "Visually similar shots and bursts",
                                emptyTitle: "No Similar Photos",
                                emptyMessage: "We will automatically group similar photos if you have more.",
                                image: viewModel.previewImages[.similarPhotos]
                            ) {
                                selectedCategory = .similarPhotos
                            }

                            // Similar Videos Card
                            SwipeHeroCard(
                                iconName: MediaCategory.similarVideos.iconName,
                                accentColor: MediaCategory.similarVideos.themeColor,
                                count: viewModel.categoryCounts[.similarVideos],
                                title: "Videos",
                                subtitle: "Visually similar recorded clips",
                                emptyTitle: "No Similar Videos",
                                emptyMessage: "We will automatically find visually similar video clips.",
                                image: viewModel.previewImages[.similarVideos]
                            ) {
                                selectedCategory = .similarVideos
                            }
                        }
                    }

                    // 3. Duplicates Section (Photos & Videos)
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Duplicates")
                            .font(.title3.bold())
                            .padding(.horizontal, AppTheme.Spacing.xs)

                        VStack(spacing: AppTheme.Spacing.sm) {
                            // Duplicate Photos Card
                            SwipeHeroCard(
                                iconName: MediaCategory.duplicatePhotos.iconName,
                                accentColor: MediaCategory.duplicatePhotos.themeColor,
                                count: viewModel.categoryCounts[.duplicatePhotos],
                                title: "Photos",
                                subtitle: "Exact identical photo copies",
                                emptyTitle: "No Duplicate Photos",
                                emptyMessage: "We will automatically detect exact duplicate photos.",
                                image: viewModel.previewImages[.duplicatePhotos]
                            ) {
                                selectedCategory = .duplicatePhotos
                            }

                            // Duplicate Videos Card
                            SwipeHeroCard(
                                iconName: MediaCategory.duplicateVideos.iconName,
                                accentColor: MediaCategory.duplicateVideos.themeColor,
                                count: viewModel.categoryCounts[.duplicateVideos],
                                title: "Videos",
                                subtitle: "Exact identical video copies",
                                emptyTitle: "No Duplicate Videos",
                                emptyMessage: "We will automatically detect exact duplicate video copies.",
                                image: viewModel.previewImages[.duplicateVideos]
                            ) {
                                selectedCategory = .duplicateVideos
                            }
                        }
                    }

                    // 4. Large Videos Section
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Large Videos")
                            .font(.title3.bold())
                            .padding(.horizontal, AppTheme.Spacing.xs)

                        SwipeHeroCard(
                            iconName: MediaCategory.largeVideos.iconName,
                            accentColor: MediaCategory.largeVideos.themeColor,
                            count: viewModel.categoryCounts[.largeVideos],
                            formattedSize: viewModel.largeVideoTotalSize > 0 ? ByteFormatter.format(viewModel.largeVideoTotalSize) : nil,
                            title: "Large Videos",
                            subtitle: "Videos taking the most device storage",
                            emptyTitle: "No Large Videos",
                            emptyMessage: "No videos found consuming significant device storage.",
                            image: viewModel.previewImages[.largeVideos]
                        ) {
                            selectedCategory = .largeVideos
                        }
                    }
                }
                .padding(AppTheme.Spacing.md)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Gallery Cleaner")
            .navigationDestination(item: $selectedCategory) { category in
                destinationView(for: category)
            }
            .task {
                await viewModel.loadCounts(force: false)
            }
            .refreshable {
                await viewModel.loadCounts(force: true)
            }
        }
    }

    @ViewBuilder
    private func destinationView(for category: MediaCategory) -> some View {
        switch category {
        case .screenshots:
            ScreenshotsView()
        case .videos:
            VideosView()
        case .duplicatePhotos:
            DuplicatePhotosView()
        case .similarPhotos:
            SimilarPhotosView()
        case .similarVideos:
            SimilarVideosView()
        case .duplicateVideos:
            DuplicateVideosView()
        case .largeVideos:
            LargeVideosView()
        }
    }
}
