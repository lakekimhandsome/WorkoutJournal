//
//  RestTimerLiveActivityController.swift
//  WorkoutJournal
//

import ActivityKit
import Foundation

@MainActor
final class RestTimerLiveActivityController {
    static let shared = RestTimerLiveActivityController()

    private var activity: Activity<RestTimerAttributes>?

    private init() {}

    func attach(_ activity: Activity<RestTimerAttributes>) {
        self.activity = activity
    }

    func startOrResume(remaining: TimeInterval) {
        guard remaining > 0 else {
            end()
            return
        }
        let state = RestTimerAttributes.ContentState.running(remaining: remaining)
        Task { await upsert(state: state, staleDate: state.endDate) }
    }

    func pause(remaining: TimeInterval) {
        guard remaining > 0 else {
            end()
            return
        }
        let state = RestTimerAttributes.ContentState.paused(remaining: remaining)
        Task { await upsert(state: state, staleDate: nil) }
    }

    func announceCompletion() {
        Task { await presentCompletion() }
    }

    func end() {
        Task { await endAll() }
    }

    private func presentCompletion() async {
        let state = RestTimerAttributes.ContentState.completed()
        let content = ActivityContent(state: state, staleDate: nil, relevanceScore: 100)
        let alert = AlertConfiguration(
            title: LocalizedStringResource("Rest Complete", locale: LanguagePreference.shared.locale),
            body: LocalizedStringResource("The rest timer has finished.", locale: LanguagePreference.shared.locale),
            sound: .default
        )

        if let activity {
            await activity.update(content, alertConfiguration: alert)
            return
        }

        if let existing = Activity<RestTimerAttributes>.activities.first {
            activity = existing
            await existing.update(content, alertConfiguration: alert)
        }
    }

    private func upsert(state: RestTimerAttributes.ContentState, staleDate: Date?) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let content = ActivityContent(state: state, staleDate: staleDate)

        if let activity {
            await activity.update(content)
            return
        }

        if let existing = Activity<RestTimerAttributes>.activities.first {
            activity = existing
            await existing.update(content)
            return
        }

        do {
            activity = try Activity.request(
                attributes: RestTimerAttributes(localeIdentifier: LanguagePreference.shared.locale.identifier),
                content: content
            )
        } catch {
            activity = nil
        }
    }

    private func endAll() async {
        let activities: [Activity<RestTimerAttributes>]
        if let activity {
            activities = [activity]
        } else {
            activities = Array(Activity<RestTimerAttributes>.activities)
        }

        for item in activities {
            await item.end(nil, dismissalPolicy: .immediate)
        }
        activity = nil
    }
}
