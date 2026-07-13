//
//  TimerManager.swift
//  WorkoutJournal
//

import Foundation
import Observation

enum RestTimerConfiguration {
    static let defaultDuration: TimeInterval = 90
}

enum RestTimerPhase: Equatable {
    case idle
    case running
    case paused
}

@Observable
@MainActor
final class TimerManager {
    static let defaultRestDuration = RestTimerConfiguration.defaultDuration

    var phase: RestTimerPhase = .idle
    var remainingSeconds: TimeInterval = RestTimerConfiguration.defaultDuration
    var isExpanded = false

    private var endDate: Date?
    private var tickTimer: Timer?

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

    func configure(duration: TimeInterval = RestTimerConfiguration.defaultDuration) {
        guard phase != .running else { return }
        remainingSeconds = duration
        if phase == .idle {
            endDate = nil
        }
    }

    func start() {
        guard phase != .running else { return }
        phase = .running
        endDate = Date().addingTimeInterval(remainingSeconds)
        startTicking()
    }

    func pause() {
        guard phase == .running else { return }
        phase = .paused
        stopTicking()
        if let endDate {
            remainingSeconds = max(0, endDate.timeIntervalSinceNow)
        }
        self.endDate = nil
    }

    func resume() {
        guard phase == .paused else { return }
        start()
    }

    func cancel() {
        stopTicking()
        endDate = nil
        phase = .idle
        remainingSeconds = Self.defaultRestDuration
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

    /// Future hook: call after completing a set to auto-start the rest timer.
    func startRestAfterSet(duration: TimeInterval = RestTimerConfiguration.defaultDuration) {
        configure(duration: duration)
        start()
    }

    private func startTicking() {
        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func stopTicking() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    private func tick() {
        guard let endDate else { return }
        remainingSeconds = max(0, endDate.timeIntervalSinceNow)
        if remainingSeconds <= 0 {
            complete()
        }
    }

    private func complete() {
        stopTicking()
        self.endDate = nil
        phase = .idle
        remainingSeconds = Self.defaultRestDuration
    }

    private static func format(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds.rounded(.up)))
        let minutes = total / 60
        let remainder = total % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }
}
