//
//  RestTimerAttributes.swift
//  WorkoutJournal
//

import ActivityKit
import Foundation

struct RestTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var startDate: Date
        var endDate: Date
        var pauseDate: Date?
        var isCompleted: Bool = false

        var isPaused: Bool { pauseDate != nil && !isCompleted }

        var timerRange: ClosedRange<Date> {
            startDate...max(startDate, endDate)
        }

        static func running(remaining: TimeInterval, now: Date = .now) -> ContentState {
            let remaining = max(0, remaining)
            return ContentState(
                startDate: now,
                endDate: now.addingTimeInterval(remaining),
                pauseDate: nil
            )
        }

        static func paused(remaining: TimeInterval, now: Date = .now) -> ContentState {
            let remaining = max(0, remaining)
            return ContentState(
                startDate: now,
                endDate: now.addingTimeInterval(remaining),
                pauseDate: now
            )
        }

        static func completed(now: Date = .now) -> ContentState {
            ContentState(
                startDate: now,
                endDate: now,
                pauseDate: now,
                isCompleted: true
            )
        }
    }
}
