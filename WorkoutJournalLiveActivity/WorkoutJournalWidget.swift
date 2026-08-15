//
//  WorkoutJournalWidget.swift
//  WorkoutJournalLiveActivity
//

import SwiftUI
import WidgetKit

struct WorkoutJournalWidget: Widget {
    let kind = "WorkoutJournalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorkoutJournalWidgetProvider()) { _ in
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "figure.strengthtraining.traditional")
                Text("운동일지")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("운동일지")
        .description("운동일지를 홈 화면에서 엽니다.")
        .supportedFamilies([.systemSmall])
    }
}

private struct WorkoutJournalWidgetEntry: TimelineEntry {
    let date: Date
}

private struct WorkoutJournalWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WorkoutJournalWidgetEntry {
        WorkoutJournalWidgetEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (WorkoutJournalWidgetEntry) -> Void) {
        completion(WorkoutJournalWidgetEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WorkoutJournalWidgetEntry>) -> Void) {
        completion(Timeline(entries: [WorkoutJournalWidgetEntry(date: .now)], policy: .never))
    }
}

#Preview(as: .systemSmall) {
    WorkoutJournalWidget()
} timeline: {
    WorkoutJournalWidgetEntry(date: .now)
}
