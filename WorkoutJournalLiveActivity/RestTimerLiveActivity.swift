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
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    RestTimerIslandButtons(state: context.state)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    RestTimerCountdownText(state: context.state)
                        .font(.largeTitle.monospacedDigit().weight(.semibold))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .multilineTextAlignment(.trailing)
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

            RestTimerCountdownText(state: state)
                .font(.largeTitle.monospacedDigit().weight(.semibold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(state.isCompleted ? "휴식 타이머 완료" : (state.isPaused ? "휴식 타이머 일시정지" : "휴식 타이머"))
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
            .accessibilityLabel(state.isPaused || state.isCompleted ? "재개" : "일시정지")

            Button(intent: CancelRestTimerIntent()) {
                Image(systemName: "xmark")
                    .font(.title.weight(.semibold))
                    .padding(-6)
            }
            .buttonBorderShape(.circle)
            .tint(.secondary)
            .accessibilityLabel("취소")
        }
        .controlSize(.large)
        .fixedSize()
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
