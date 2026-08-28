//
//  RestTimerLiveActivity.swift
//  WorkoutJournalLiveActivity
//

import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct RestTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerAttributes.self) { context in
            RestTimerLockScreenView(state: context.state)
                .padding()
                .environment(\.locale, context.attributes.locale)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    RestTimerIslandButtons(state: context.state)
                        .environment(\.locale, context.attributes.locale)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    RestTimerLabeledCountdown(state: context.state)
                        .environment(\.locale, context.attributes.locale)
                        .frame(maxHeight: .infinity, alignment: .center)
                }
            } compactLeading: {
                Image(systemName: context.state.isCompleted ? "checkmark" : (context.state.isPaused ? "pause.fill" : "timer"))
            } compactTrailing: {
                RestTimerCountdownText(state: context.state)
                    .font(.body.monospacedDigit().weight(.semibold))
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: 56)
            } minimal: {
                Image(systemName: context.state.isCompleted ? "checkmark" : (context.state.isPaused ? "pause.fill" : "timer"))
            }
        }
    }
}

private struct RestTimerLockScreenView: View {
    let state: RestTimerAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            RestTimerIslandButtons(state: state)

            Spacer(minLength: 8)

            RestTimerLabeledCountdown(state: state)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: LocalizedStringKey {
        if state.isCompleted {
            "Rest timer complete"
        } else if state.isPaused {
            "Rest timer paused"
        } else {
            "Rest timer"
        }
    }
}

private struct RestTimerIslandButtons: View {
    let state: RestTimerAttributes.ContentState

    var body: some View {
        HStack(spacing: 8) {
            Button(intent: ToggleRestTimerIntent()) {
                Image(systemName: state.isPaused || state.isCompleted ? "play.fill" : "pause.fill")
                    .font(.title.weight(.semibold))
                    .padding(-6)
            }
            .buttonBorderShape(.circle)
            .tint(.white)
            .accessibilityLabel(state.isPaused || state.isCompleted ? LocalizedStringKey("Resume") : LocalizedStringKey("Pause"))

            Button(intent: CancelRestTimerIntent()) {
                Image(systemName: "xmark")
                    .font(.title.weight(.semibold))
                    .padding(-6)
            }
            .buttonBorderShape(.circle)
            .tint(.secondary)
            .accessibilityLabel("Cancel")
        }
        .controlSize(.large)
        .fixedSize()
    }
}

private struct RestTimerLabeledCountdown: View {
    let state: RestTimerAttributes.ContentState

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: -18) {
            Text("Rest")
                .font(.body)
                .foregroundStyle(.white)

            Text("59:59")
                .font(.system(size: 44, weight: .light).monospacedDigit())
                .hidden()
                .overlay(alignment: .leading) {
                    RestTimerCountdownText(state: state)
                        .font(.system(size: 44, weight: .light).monospacedDigit())
                        .lineLimit(1)
                        .offset(x: -3)
                }
        }
        .fixedSize()
        .padding(.trailing, 10)
    }
}

struct RestTimerCountdownText: View {
    let state: RestTimerAttributes.ContentState

    var body: some View {
        Text(
            timerInterval: state.timerRange,
            pauseTime: state.pauseDate,
            countsDown: true,
            showsHours: false
        )
        .monospacedDigit()
        .multilineTextAlignment(.trailing)
    }
}

#Preview("Lock Screen", as: .content, using: RestTimerAttributes()) {
    RestTimerLiveActivity()
} contentStates: {
    RestTimerAttributes.ContentState.running(remaining: 5)
    RestTimerAttributes.ContentState.paused(remaining: 5)
    RestTimerAttributes.ContentState.completed()
}

#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: RestTimerAttributes()) {
    RestTimerLiveActivity()
} contentStates: {
    RestTimerAttributes.ContentState.running(remaining: 5)
}

#Preview("Dynamic Island Minimal", as: .dynamicIsland(.minimal), using: RestTimerAttributes()) {
    RestTimerLiveActivity()
} contentStates: {
    RestTimerAttributes.ContentState.running(remaining: 5)
}

#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: RestTimerAttributes()) {
    RestTimerLiveActivity()
} contentStates: {
    RestTimerAttributes.ContentState.running(remaining: 5)
    RestTimerAttributes.ContentState.paused(remaining: 5)
    RestTimerAttributes.ContentState.completed()
}
