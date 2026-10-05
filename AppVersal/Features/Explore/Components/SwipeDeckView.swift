//
//  SwipeDeckView.swift
//  AppVersal
//

import SwiftUI
import Photos

public struct SwipeDeckView: View {
    @StateObject private var viewModel: SwipeDeckViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var dragOffset: CGSize = .zero
    @State private var isAnimatingAction: Bool = false

    public init(title: String, items: [MediaItem]) {
        _viewModel = StateObject(wrappedValue: SwipeDeckViewModel(title: title, items: items))
    }

    public var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Apple HIG Header Bar
                headerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 10)

                // Sleek Apple Progress Line
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(UIColor.quaternarySystemFill))
                            .frame(height: 3)

                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: max(3, geo.size.width * CGFloat(viewModel.progress)), height: 3)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.progress)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                if viewModel.isCompleted {
                    // Apple HIG Celebration Completion Screen
                    completionView
                } else if viewModel.remainingItems.isEmpty {
                    emptyDeckView
                } else {
                    // Card Deck
                    cardDeckArea
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)

                    // Apple HIG Bottom Control Dock
                    bottomActionBar
                        .padding(.horizontal, 32)
                        .padding(.bottom, 20)
                        .padding(.top, 14)
                }
            }
        }
    }

    // MARK: - Apple HIG Standard Header Bar
    private var headerBar: some View {
        HStack {
            // Standard iOS Close Button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Centered Batch Title & Counter
            VStack(spacing: 2) {
                Text(viewModel.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Photo \(min(viewModel.initialCount, viewModel.swipedCount + 1)) of \(viewModel.initialCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Standard iOS Undo Button in Header
            Button {
                viewModel.undoLast()
            } label: {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 30))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(viewModel.canUndo ? .orange : Color(UIColor.systemGray4))
            }
            .disabled(!viewModel.canUndo)
        }
    }

    // MARK: - Card Stack Area
    private var cardDeckArea: some View {
        GeometryReader { geo in
            ZStack {
                // Next Card (Underneath Stack)
                if let next = viewModel.nextItem {
                    let dragProgress = min(1.0, abs(dragOffset.width) / 120.0)
                    let scale = 0.94 + (0.06 * dragProgress)
                    let yOffset = 14.0 - (14.0 * dragProgress)

                    SwipeCardView(item: next, dragOffset: .zero, isTopCard: false)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .scaleEffect(scale)
                        .offset(y: yOffset)
                        .opacity(0.85 + (0.15 * dragProgress))
                }

                // Current Active Top Card
                if let current = viewModel.currentItem {
                    SwipeCardView(item: current, dragOffset: dragOffset, isTopCard: true)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .offset(x: dragOffset.width, y: dragOffset.height * 0.15)
                        .rotationEffect(.degrees(Double(dragOffset.width / 18)))
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    guard !isAnimatingAction else { return }
                                    dragOffset = gesture.translation
                                }
                                .onEnded { gesture in
                                    guard !isAnimatingAction else { return }
                                    handleDragEnd(translation: gesture.translation)
                                }
                        )
                }
            }
        }
    }

    // MARK: - Apple HIG Bottom Action Controls (Frosted Glass Materials)
    private var bottomActionBar: some View {
        HStack {
            // Undo Button
            Button {
                viewModel.undoLast()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(Color(UIColor.separator).opacity(0.25), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)

                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(viewModel.canUndo ? .orange : Color(UIColor.systemGray4))
                }
            }
            .disabled(!viewModel.canUndo)

            Spacer()

            // Trash Button (Swipe Left)
            Button {
                triggerProgrammaticSwipe(direction: .trash)
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 66, height: 66)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.red.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: Color.red.opacity(0.18), radius: 8, x: 0, y: 4)

                    Image(systemName: "trash.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.red)
                }
            }
            .disabled(isAnimatingAction || viewModel.currentItem == nil)

            Spacer()

            // Keep Button (Swipe Right)
            Button {
                triggerProgrammaticSwipe(direction: .keep)
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 66, height: 66)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.green.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: Color.green.opacity(0.18), radius: 8, x: 0, y: 4)

                    Image(systemName: "checkmark")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            .disabled(isAnimatingAction || viewModel.currentItem == nil)
        }
    }

    // MARK: - Gesture Handling
    private func handleDragEnd(translation: CGSize) {
        let threshold: CGFloat = 110

        if translation.width > threshold {
            // Fling Right -> Keep
            animateFling(to: CGSize(width: 600, height: translation.height)) {
                viewModel.keepCurrent()
            }
        } else if translation.width < -threshold {
            // Fling Left -> Trash
            animateFling(to: CGSize(width: -600, height: translation.height)) {
                viewModel.trashCurrent()
            }
        } else {
            // Snap back to center
            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                dragOffset = .zero
            }
        }
    }

    private func triggerProgrammaticSwipe(direction: SwipeAction) {
        guard !isAnimatingAction else { return }
        let targetX: CGFloat = direction == .keep ? 600 : -600
        animateFling(to: CGSize(width: targetX, height: 0)) {
            if direction == .keep {
                viewModel.keepCurrent()
            } else {
                viewModel.trashCurrent()
            }
        }
    }

    private func animateFling(to target: CGSize, onCompletion: @escaping () -> Void) {
        isAnimatingAction = true
        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
            dragOffset = target
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            onCompletion()
            dragOffset = .zero
            isAnimatingAction = false
        }
    }

    // MARK: - Apple HIG Completion Celebration View
    private var completionView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 96, height: 96)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
            }

            VStack(spacing: 6) {
                Text("Review Complete")
                    .font(.title2.bold())
                    .foregroundColor(.primary)

                Text("All photos in \(viewModel.title) have been reviewed.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // iOS HIG Grouped Summary Card
            VStack(spacing: 0) {
                HStack {
                    Label("Photos Kept", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Spacer()
                    Text("\(viewModel.keptItems.count)")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider()
                    .padding(.leading, 16)

                HStack {
                    Label("Moved to Trash", systemImage: "trash.fill")
                        .foregroundColor(.red)
                    Spacer()
                    Text("\(viewModel.trashedItems.count)")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                if viewModel.totalTrashedBytes > 0 {
                    Divider()
                        .padding(.leading, 16)

                    HStack {
                        Label("Reclaimable Space", systemImage: "internaldrive.fill")
                            .foregroundColor(.blue)
                        Spacer()
                        Text(ByteFormatter.format(viewModel.totalTrashedBytes))
                            .font(.headline.bold())
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 24)

            Spacer()

            // Primary Apple-style Action Button
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .padding(AppTheme.Spacing.md)
    }

    private var emptyDeckView: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Spacer()
            Image(systemName: "photo.stack")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No photos to review")
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}
