//
//  WorkoutJournalApp.swift
//  WorkoutJournal
//
//  Created by 김호수 on 7/11/26.
//

import SwiftUI

@main
struct WorkoutJournalApp: App {
    @State private var timerManager = TimerManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(timerManager)
        }
        .onChange(of: scenePhase) { _, newPhase in
            timerManager.handleScenePhaseChanged(isActive: newPhase == .active)
        }
    }
}
