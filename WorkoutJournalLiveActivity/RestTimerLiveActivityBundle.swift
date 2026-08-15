//
//  RestTimerLiveActivityBundle.swift
//  WorkoutJournalLiveActivity
//

import SwiftUI
import WidgetKit

@main
struct RestTimerLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        WorkoutJournalWidget()
        RestTimerLiveActivity()
    }
}
