import Foundation

struct SessionDateGroup: Identifiable {
    var id: SessionDateSection { section }
    let section: SessionDateSection
    let sessions: [WorkoutSession]
}

enum SessionDateSection: Hashable, Comparable {
    case today
    case yesterday
    case previous7Days
    case previous30Days
    case month(year: Int, month: Int)
    case year(Int)

    var title: String {
        switch self {
        case .today:
            "오늘"
        case .yesterday:
            "어제"
        case .previous7Days:
            "이전 7일"
        case .previous30Days:
            "이전 30일"
        case .month(let year, let month):
            Self.date(year: year, month: month)
                .formatted(.dateTime.month(.wide))
        case .year(let year):
            Self.date(year: year)
                .formatted(.dateTime.year())
        }
    }

    init(date: Date, now: Date = .now, calendar: Calendar = .autoupdatingCurrent) {
        let startOfNow = calendar.startOfDay(for: now)
        let startOfDate = calendar.startOfDay(for: date)

        if startOfDate >= startOfNow {
            self = .today
            return
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfNow),
           startOfDate >= yesterday {
            self = .yesterday
            return
        }

        if let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: startOfNow),
           startOfDate >= sevenDaysAgo {
            self = .previous7Days
            return
        }

        if let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: startOfNow),
           startOfDate >= thirtyDaysAgo {
            self = .previous30Days
            return
        }

        let year = calendar.component(.year, from: startOfDate)
        if year == calendar.component(.year, from: startOfNow) {
            self = .month(year: year, month: calendar.component(.month, from: startOfDate))
        } else {
            self = .year(year)
        }
    }

    static func groups(
        from sessions: [WorkoutSession],
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [SessionDateGroup] {
        Dictionary(grouping: sessions) { SessionDateSection(date: $0.date, now: now, calendar: calendar) }
            .map { SessionDateGroup(section: $0.key, sessions: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.section < $1.section }
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.sortKey < rhs.sortKey
    }

    private var sortKey: (Int, Int) {
        switch self {
        case .today: (0, 0)
        case .yesterday: (1, 0)
        case .previous7Days: (2, 0)
        case .previous30Days: (3, 0)
        case .month(let year, let month): (4, -(year * 100 + month))
        case .year(let year): (5, -year)
        }
    }

    private static func date(year: Int, month: Int = 1) -> Date {
        Calendar.autoupdatingCurrent.date(from: DateComponents(year: year, month: month, day: 1)) ?? .now
    }
}
