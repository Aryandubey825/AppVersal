//
//  YearDetailView.swift
//  AppVersal
//

import SwiftUI
import Photos

public struct YearDetailView: View {
    public let yearlyGroup: YearlyGroup

    @State private var selectedMonth: MonthGroup? = nil
    @State private var isSwipingAllYear: Bool = false

    public init(yearlyGroup: YearlyGroup) {
        self.yearlyGroup = yearlyGroup
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                // Quick Clean Entire Year Hero Card
                cleanAllYearCard

                // Months to Review List
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Text("Months to Review")
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                        .padding(.horizontal, 4)

                    ForEach(yearlyGroup.months) { month in
                        MonthHeroCard(
                            title: month.title,
                            itemCount: month.items.count,
                            formattedSize: month.formattedTotalSize,
                            previewAsset: month.previewAsset
                        ) {
                            selectedMonth = month
                        }
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
        }
        .navigationTitle(String(yearlyGroup.year))
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(item: $selectedMonth) { month in
            SwipeDeckView(title: month.title, items: month.items)
        }
        .fullScreenCover(isPresented: $isSwipingAllYear) {
            SwipeDeckView(title: String(yearlyGroup.year), items: yearlyGroup.items)
        }
    }

    // MARK: - Clean All Year Hero Card
    private var cleanAllYearCard: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack {
                Spacer()
                Image(systemName: "hand.draw.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.12))
                    .rotationEffect(.degrees(-12))
                    .offset(x: 10, y: -5)
            }

            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Clean Entire Year")
                        .font(.title3.bold())
                        .foregroundColor(.white)

                    Text("\(yearlyGroup.items.count) photos • \(yearlyGroup.formattedTotalSize)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }

                Button {
                    isSwipingAllYear = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11))
                        Text("Start Swiping All")
                            .font(.subheadline.bold())
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                    )
                }
            }
            .padding(20)
        }
        .frame(height: 155)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.blue.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}
