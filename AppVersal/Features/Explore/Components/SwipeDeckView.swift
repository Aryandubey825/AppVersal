import SwiftUI
import Photos

public struct SwipeDeckView: View {
    @StateObject private var viewModel: SwipeDeckViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var dragOffset: CGSize = .zero
    @State private var isAnimatingAction: Bool = false

    public init(title: String, items: [MediaItem], monthId: String? = nil) {
        _viewModel = StateObject(wrappedValue: SwipeDeckViewModel(title: title, items: items, monthId: monthId))
    }

    public var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.14))
                            .frame(height: 8)

                        Capsule()
                            .fill(Color.white.opacity(0.75))
                            .frame(width: max(8, geo.size.width * CGFloat(viewModel.progress)), height: 8)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.progress)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, 20)
                .padding(.top, 10)

                HStack {
                    Text("Swiped \(viewModel.swipedCount) / \(viewModel.initialCount) elements")
                        .font(.footnote.weight(.medium))
                        .foregroundColor(.white.opacity(0.72))

                    Spacer()

                    Text("Saved \(viewModel.totalTrashedBytes > 0 ? ByteFormatter.format(viewModel.totalTrashedBytes) : "0 MB")")
                        .font(.footnote.weight(.medium))
                        .foregroundColor(.white.opacity(0.72))
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 8)

                if viewModel.isCompleted {
                    completionView
                } else if viewModel.remainingItems.isEmpty {
                    emptyDeckView
                } else {
                    cardStackDeck
                        .padding(.horizontal, 16)
                        .padding(.bottom, 18)
                }
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.undoLast()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .disabled(!viewModel.canUndo)
                .accessibilityLabel("Undo last swipe")
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.keptItems.count)
        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.trashedItems.count)
        .sensoryFeedback(.success, trigger: viewModel.isCompleted)
    }

    private var cardStackDeck: some View {
        GeometryReader { geo in
            let availableWidth = geo.size.width
            let availableHeight = geo.size.height
            let topStackSpace: CGFloat = 66
            let cardHeight = max(240, availableHeight - topStackSpace)
            let dragProgress = min(1.0, abs(dragOffset.width) / 120.0)

            ZStack(alignment: .bottom) {
                if viewModel.remainingItems.count > 3 {
                    let item4 = viewModel.remainingItems[3]
                    let targetY = -60.0 + (20.0 * dragProgress)
                    let targetScale = 0.88 + (0.04 * dragProgress)
                    SwipeCardView(item: item4, isTopCard: false)
                        .frame(width: availableWidth, height: cardHeight)
                        .scaleEffect(targetScale)
                        .offset(y: targetY)
                        .opacity(0.65)
                }

                if viewModel.remainingItems.count > 2 {
                    let item3 = viewModel.remainingItems[2]
                    let targetY = -40.0 + (20.0 * dragProgress)
                    let targetScale = 0.92 + (0.04 * dragProgress)
                    SwipeCardView(item: item3, isTopCard: false)
                        .frame(width: availableWidth, height: cardHeight)
                        .scaleEffect(targetScale)
                        .offset(y: targetY)
                        .opacity(0.8)
                }

                if let next = viewModel.nextItem {
                    let targetY = -20.0 + (20.0 * dragProgress)
                    let targetScale = 0.96 + (0.04 * dragProgress)
                    SwipeCardView(item: next, isTopCard: false)
                        .frame(width: availableWidth, height: cardHeight)
                        .scaleEffect(targetScale)
                        .offset(y: targetY)
                        .opacity(0.92)
                }

                if let current = viewModel.currentItem {
                    SwipeCardView(
                        item: current,
                        dragOffset: dragOffset,
                        isTopCard: true,
                        onTrashTap: { triggerProgrammaticSwipe(direction: .trash) },
                        onKeepTap: { triggerProgrammaticSwipe(direction: .keep) }
                    )
                    .frame(width: availableWidth, height: cardHeight)
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
            .frame(width: availableWidth, height: availableHeight, alignment: .bottom)
        }
    }

    private func handleDragEnd(translation: CGSize) {
        let threshold: CGFloat = 110

        if translation.width > threshold {
            animateFling(to: CGSize(width: 600, height: translation.height)) {
                viewModel.keepCurrent()
            }
        } else if translation.width < -threshold {
            animateFling(to: CGSize(width: -600, height: translation.height)) {
                viewModel.trashCurrent()
            }
        } else {
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
                    .symbolEffect(.bounce)
            }

            VStack(spacing: 6) {
                Text("Review Complete")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text("All photos in \(viewModel.title) have been reviewed.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 0) {
                HStack {
                    Label("Photos Kept", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Spacer()
                    Text("\(viewModel.keptItems.count)")
                        .font(.headline)
                        .foregroundColor(.white)
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
                        .foregroundColor(.white)
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
            .background(Color(UIColor.secondarySystemGroupedBackground).opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 24)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
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
                .foregroundColor(.white.opacity(0.4))
            Text("No photos to review")
                .font(.headline)
                .foregroundColor(.white.opacity(0.6))
            Spacer()
        }
    }
}
