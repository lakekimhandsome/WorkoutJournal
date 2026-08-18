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
    @State private var sessionStore = SessionStore.shared
    @State private var authManager = AuthManager.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        _ = PhoneWatchSyncManager.shared
        AuthManager.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(timerManager)
                .environment(sessionStore)
                .environment(authManager)
                .onOpenURL(perform: authManager.handleOpenURL)
        }
        .onChange(of: scenePhase) { _, newPhase in
            timerManager.handleScenePhaseChanged(isActive: newPhase == .active)
            if newPhase == .active {
                PhoneWatchSyncManager.shared.syncIfNeeded()
            }
        }
    }
}
