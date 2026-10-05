//
//  YearDetailView.swift
//  AppVersal
//

import SwiftUI
import Photos

public struct YearDetailView: View {
    public let year: Int
    @ObservedObject public var exploreViewModel: ExploreViewModel

    @State private var selectedMonth: MonthGroup? = nil

    public init(year: Int, exploreViewModel: ExploreViewModel) {
        self.year = year
        self.exploreViewModel = exploreViewModel
    }

    public init(yearlyGroup: YearlyGroup) {
        self.year = yearlyGroup.year
        self.exploreViewModel = ExploreViewModel()
    }

    private var currentYearlyGroup: YearlyGroup? {
        exploreViewModel.yearlyGroups.first(where: { $0.year == year })
    }

    public var body: some View {
        let months = currentYearlyGroup?.months ?? []
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 24) {
                ForEach(months) { month in
                    SwAipeMonthStackCard(month: month) {
                        selectedMonth = month
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .navigationTitle(String(year))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Text("\(currentYearlyGroup?.items.count ?? 0) items in \(year)")
                    Text(currentYearlyGroup?.formattedTotalSize ?? "0 MB")
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .navigationDestination(item: $selectedMonth) { month in
            SwipeDeckView(
                title: month.monthName,
                items: month.items,
                monthId: month.id
            )
        }
    }
}
