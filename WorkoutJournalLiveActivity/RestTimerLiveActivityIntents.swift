//
//  RestTimerLiveActivityIntents.swift
//  WorkoutJournal
//

import ActivityKit
import AppIntents
import Foundation

struct ToggleRestTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause or Resume"
    static var description = IntentDescription("Pauses or resumes the rest timer.")
    static var isDiscoverable = false

    func perform() async throws -> some IntentResult {
        #if WIDGET_EXTENSION
        await RestTimerLiveActivityRemoteControls.togglePause()
        #else
        await toggleInApp()
        #endif
        return .result()
    }

    #if !WIDGET_EXTENSION
    @MainActor
    private func toggleInApp() {
        switch TimerManager.shared.phase {
        case .running:
            TimerManager.shared.pause()
        case .paused:
            TimerManager.shared.resume()
        case .idle:
            break
        }
    }
    #endif
}

struct CancelRestTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Cancel"
    static var description = IntentDescription("Cancels the rest timer.")
    static var isDiscoverable = false

    func perform() async throws -> some IntentResult {
        #if WIDGET_EXTENSION
        await RestTimerLiveActivityRemoteControls.cancel()
        #else
        await cancelInApp()
        #endif
        return .result()
    }

    #if !WIDGET_EXTENSION
    @MainActor
    private func cancelInApp() {
        TimerManager.shared.cancel()
    }
    #endif
}

#if WIDGET_EXTENSION
private enum RestTimerLiveActivityRemoteControls {
    static func togglePause() async {
        guard let activity = Activity<RestTimerAttributes>.activities.first else { return }
        let state = activity.content.state

        if state.isCompleted { return }

        if state.isPaused {
            let remaining = max(0, state.endDate.timeIntervalSince(state.pauseDate ?? .now))
            let next = RestTimerAttributes.ContentState.running(remaining: remaining)
            await activity.update(.init(state: next, staleDate: next.endDate))
        } else {
            let remaining = max(0, state.endDate.timeIntervalSinceNow)
            let next = RestTimerAttributes.ContentState.paused(remaining: remaining)
            await activity.update(.init(state: next, staleDate: nil))
        }
    }

    static func cancel() async {
        for activity in Activity<RestTimerAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
#endif
