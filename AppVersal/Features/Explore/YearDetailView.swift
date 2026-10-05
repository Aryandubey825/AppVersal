import SwiftUI
import Photos

public struct YearDetailView: View {
    public let year: Int
    @ObservedObject public var exploreViewModel: ExploreViewModel

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
            LazyVStack(spacing: 32) {
                ForEach(months) { month in
                    NavigationLink(value: month) {
                        SwAipeMonthStackCard(month: month)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .navigationTitle(String(year))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Text("\(currentYearlyGroup?.items.count ?? 0) items in \(year)")
                    Text(currentYearlyGroup?.formattedTotalSize ?? "0 MB")
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
        }
        .navigationDestination(for: MonthGroup.self) { month in
            SwipeDeckView(
                title: month.monthName,
                items: month.items,
                monthId: month.id
            )
        }
    }
}
