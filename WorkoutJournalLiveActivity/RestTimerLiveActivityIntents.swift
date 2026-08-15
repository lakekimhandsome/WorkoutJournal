//
//  RestTimerLiveActivityIntents.swift
//  WorkoutJournal
//

import ActivityKit
import AppIntents
import Foundation

struct ToggleRestTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "일시정지 또는 재개"
    static var description = IntentDescription("휴식 타이머를 일시정지하거나 재개합니다.")
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
    static var title: LocalizedStringResource = "취소"
    static var description = IntentDescription("휴식 타이머를 취소합니다.")
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
