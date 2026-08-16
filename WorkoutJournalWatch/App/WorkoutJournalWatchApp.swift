import SwiftUI

@main
struct WorkoutJournalWatchApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        _ = WatchPhoneSyncManager.shared
    }

    var body: some Scene {
        WindowGroup {
            IdleView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                WatchPhoneSyncManager.shared.syncIfNeeded()
            }
        }
    }
}
