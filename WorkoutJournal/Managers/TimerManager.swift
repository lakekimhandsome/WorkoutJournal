//
//  TimerManager.swift
//  WorkoutJournal
//

import ActivityKit
import Foundation
import Observation
import Supabase
import UIKit

enum RestTimerConfiguration {
    static let defaultDuration: TimeInterval = 5
}

enum RestTimerPhase: Equatable {
    case idle
    case running
    case paused
}

@Observable
@MainActor
final class TimerManager {
    static let shared = TimerManager()

    var phase: RestTimerPhase = .idle
    var remainingSeconds: TimeInterval = RestTimerConfiguration.defaultDuration
    var configuredDuration: TimeInterval = RestTimerConfiguration.defaultDuration
    var isExpanded = false

    private var endDate: Date?
    private var tickTimer: Timer?
    private var completionTimer: Timer?
    private var isAppActive = true
    private var currentUserID: UUID?

    init() {
        restoreFromLiveActivityIfNeeded()
    }

    var formattedRemainingTime: String {
        Self.format(remainingSeconds)
    }

    var primaryActionIcon: String {
        switch phase {
        case .idle, .paused:
            "play.fill"
        case .running:
            "pause.fill"
        }
    }

    var isCancelEnabled: Bool {
        phase != .idle
    }

    func toggleExpanded() {
        isExpanded.toggle()
    }

    func configure(duration: TimeInterval) {
        let duration = max(1, duration.rounded())
        applyConfiguredDuration(duration)
        persistConfiguredDuration()
    }

    func loadRemote(userID: UUID) async {
        currentUserID = userID

        do {
            let rows: [RestTimerPreferenceRecord] = try await SupabaseService.client
                .from("workoutjournal_preferences")
                .select("rest_timer_duration_seconds")
                .eq("user_id", value: userID)
                .limit(1)
                .execute()
                .value

            guard currentUserID == userID else { return }
            let duration = rows.first.map { TimeInterval($0.restTimerDurationSeconds) }
                ?? RestTimerConfiguration.defaultDuration
            applyStoredDuration(duration)
        } catch {
            guard currentUserID == userID else { return }
            applyStoredDuration(RestTimerConfiguration.defaultDuration)
        }
    }

    func resetAccountSettings() {
        currentUserID = nil
        applyStoredDuration(RestTimerConfiguration.defaultDuration)
    }

    private func applyStoredDuration(_ duration: TimeInterval) {
        configuredDuration = min(max(1, duration.rounded()), 59 * 60 + 59)
        if phase == .idle {
            remainingSeconds = configuredDuration
        }
    }

    private func applyConfiguredDuration(_ duration: TimeInterval) {
        let duration = min(max(1, duration.rounded()), 59 * 60 + 59)
        configuredDuration = duration
        remainingSeconds = duration

        switch phase {
        case .idle:
            endDate = nil
        case .paused:
            endDate = nil
            RestTimerLiveActivityController.shared.pause(remaining: remainingSeconds)
        case .running:
            endDate = Date().addingTimeInterval(remainingSeconds)
            startTicking()
            RestTimerLiveActivityController.shared.startOrResume(remaining: remainingSeconds)
        }
    }

    private func persistConfiguredDuration() {
        guard let currentUserID else { return }
        let record = RestTimerPreferenceUpsert(
            userID: currentUserID,
            restTimerDurationSeconds: Int(configuredDuration),
            updatedAt: .now
        )

        Task {
            try? await SupabaseService.client
                .from("workoutjournal_preferences")
                .upsert(record)
                .execute()
        }
    }

    func start() {
        guard phase != .running else { return }
        phase = .running
        endDate = Date().addingTimeInterval(remainingSeconds)
        startTicking()
        RestTimerLiveActivityController.shared.startOrResume(remaining: remainingSeconds)
    }

    func pause() {
        guard phase == .running else { return }
        phase = .paused
        stopTicking()
        if let endDate {
            remainingSeconds = max(0, endDate.timeIntervalSinceNow)
        }
        self.endDate = nil
        RestTimerLiveActivityController.shared.pause(remaining: remainingSeconds)
    }

    func resume() {
        guard phase == .paused else { return }
        start()
    }

    func cancel() {
        stopTicking()
        endDate = nil
        phase = .idle
        remainingSeconds = configuredDuration
        RestTimerLiveActivityController.shared.end()
    }

    func reset() {
        cancel()
    }

    func performPrimaryAction() {
        switch phase {
        case .idle:
            start()
        case .running:
            pause()
        case .paused:
            resume()
        }
    }

    /// Restarts the rest timer after completing a set.
    func startRestAfterSet(duration: TimeInterval? = nil) {
        stopTicking()
        endDate = nil
        phase = .idle
        remainingSeconds = duration ?? configuredDuration
        start()
    }

    func handleScenePhaseChanged(isActive: Bool) {
        isAppActive = isActive
        if isActive {
            restoreFromLiveActivityIfNeeded()
        }
    }

    private func restoreFromLiveActivityIfNeeded() {
        guard let activity = Activity<RestTimerAttributes>.activities.first else {
            if phase != .idle {
                stopTicking()
                endDate = nil
                phase = .idle
                remainingSeconds = configuredDuration
            }
            return
        }

        RestTimerLiveActivityController.shared.attach(activity)
        let state = activity.content.state

        if state.isCompleted {
            stopTicking()
            endDate = nil
            phase = .idle
            remainingSeconds = configuredDuration
            RestTimerLiveActivityController.shared.end()
            return
        }

        if let pauseDate = state.pauseDate {
            stopTicking()
            phase = .paused
            remainingSeconds = max(0, state.endDate.timeIntervalSince(pauseDate))
            endDate = nil
            return
        }

        let remaining = state.endDate.timeIntervalSinceNow
        if remaining <= 0 {
            complete()
            return
        }

        phase = .running
        endDate = state.endDate
        remainingSeconds = remaining
        if tickTimer == nil {
            startTicking()
        }
    }

    private func startTicking() {
        tickTimer?.invalidate()
        completionTimer?.invalidate()

        tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }

        if let endDate {
            let timer = Timer(fire: endDate, interval: 0, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.complete()
                }
            }
            timer.tolerance = 0
            RunLoop.main.add(timer, forMode: .common)
            completionTimer = timer
        }
    }

    private func stopTicking() {
        tickTimer?.invalidate()
        tickTimer = nil
        completionTimer?.invalidate()
        completionTimer = nil
    }

    private func tick() {
        guard phase == .running, let endDate else { return }
        remainingSeconds = max(0, endDate.timeIntervalSinceNow)
        if remainingSeconds <= 0 {
            complete()
        }
    }

    private func complete() {
        guard phase == .running else { return }

        stopTicking()
        endDate = nil
        phase = .idle
        remainingSeconds = configuredDuration

        playCompletionHaptic()

        if isAppActive {
            RestTimerLiveActivityController.shared.end()
        } else {
            RestTimerLiveActivityController.shared.announceCompletion()
        }
    }

    private func playCompletionHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    private static func format(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds.rounded(.up)))
        let minutes = total / 60
        let remainder = total % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }
}

private struct RestTimerPreferenceRecord: Decodable {
    let restTimerDurationSeconds: Int

    enum CodingKeys: String, CodingKey {
        case restTimerDurationSeconds = "rest_timer_duration_seconds"
    }
}

private struct RestTimerPreferenceUpsert: Encodable {
    let userID: UUID
    let restTimerDurationSeconds: Int
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case restTimerDurationSeconds = "rest_timer_duration_seconds"
        case updatedAt = "updated_at"
    }
}
