import Foundation

public enum DateFilterPreset: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case today = "Today"
    case past7Days = "Last 7 Days"
    case past30Days = "Last 30 Days"
    case thisMonth = "This Month"
    case thisYear = "This Year"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .all: return "All"
        case .today: return "Today"
        case .past7Days: return "Last 7 Days"
        case .past30Days: return "Last 30 Days"
        case .thisMonth: return "This Month"
        case .thisYear: return "This Year"
        }
    }
}

public enum DateFilterOption: Equatable, Hashable, Sendable {
    case preset(DateFilterPreset)
    case custom(start: Date, end: Date)

    public static let all: DateFilterOption = .preset(.all)
    public static let today: DateFilterOption = .preset(.today)
    public static let past7Days: DateFilterOption = .preset(.past7Days)
    public static let past30Days: DateFilterOption = .preset(.past30Days)
    public static let thisMonth: DateFilterOption = .preset(.thisMonth)
    public static let thisYear: DateFilterOption = .preset(.thisYear)

    public static let standardPresets: [DateFilterOption] = [
        .all,
        .today,
        .past7Days,
        .past30Days,
        .thisMonth,
        .thisYear
    ]

    public var title: String {
        switch self {
        case .preset(let preset):
            return preset.title
        case .custom(let start, let end):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
        }
    }

    public var shortTitle: String {
        switch self {
        case .preset(let preset):
            return preset.title
        case .custom(let start, let end):
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
        }
    }

    public var isFiltered: Bool {
        switch self {
        case .preset(let p):
            return p != .all
        case .custom:
            return true
        }
    }

    public func matches(date: Date?) -> Bool {
        guard isFiltered else { return true }
        guard let date = date else { return false }

        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .preset(.all):
            return true

        case .preset(.today):
            return calendar.isDateInToday(date)

        case .preset(.past7Days):
            guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: now)) else { return true }
            return date >= sevenDaysAgo

        case .preset(.past30Days):
            guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: calendar.startOfDay(for: now)) else { return true }
            return date >= thirtyDaysAgo

        case .preset(.thisMonth):
            return calendar.isDate(date, equalTo: now, toGranularity: .month) && calendar.isDate(date, equalTo: now, toGranularity: .year)

        case .preset(.thisYear):
            return calendar.isDate(date, equalTo: now, toGranularity: .year)

        case .custom(let start, let end):
            let startDay = calendar.startOfDay(for: min(start, end))
            let endDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: max(start, end)) ?? max(start, end)
            return date >= startDay && date <= endDay
        }
    }
}
