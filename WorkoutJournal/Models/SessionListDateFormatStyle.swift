//
//  SessionListDateFormatStyle.swift
//  WorkoutJournal
//

import Foundation

struct SessionListDateFormatStyle: FormatStyle {
    func format(_ value: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let sessionDay = calendar.startOfDay(for: value)
        let daysAgo = calendar.dateComponents([.day], from: sessionDay, to: today).day ?? 0

        switch daysAgo {
        case 0:
            return "오늘"
        case 1:
            return "어제"
        case 2...6:
            return value.formatted(
                .dateTime
                    .weekday(.wide)
                    .locale(Locale(identifier: "ko_KR"))
            )
        default:
            let formatter = DateFormatter()
            formatter.calendar = .current
            formatter.locale = .current
            formatter.dateFormat = "yyyy. M. d"
            return formatter.string(from: value)
        }
    }
}

extension FormatStyle where Self == SessionListDateFormatStyle {
    static var sessionList: SessionListDateFormatStyle { SessionListDateFormatStyle() }
}
