//
//  RestTimerView.swift
//  WorkoutJournal
//

import SwiftUI

struct RestTimerView: View {
    @Environment(TimerManager.self) private var timerManager

    var body: some View {
        Group {
            if timerManager.isExpanded {
                expandedContent
            } else {
                compactContent
            }
        }
        .glassEffect(.regular, in: .rect(cornerRadius: timerManager.isExpanded ? 20 : 14))
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: timerManager.isExpanded)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var compactContent: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                    timerManager.toggleExpanded()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(timerManager.formattedRemainingTime)
                        .font(.body.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                timerManager.reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .controlSize(.regular)
            .accessibilityLabel("초기화")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var expandedContent: some View {
        VStack(spacing: 20) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                    timerManager.isExpanded = false
                }
            } label: {
                Capsule()
                    .fill(.secondary.opacity(0.35))
                    .frame(width: 36, height: 5)
                    .padding(.top, 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("접기")

            Text(timerManager.formattedRemainingTime)
                .font(.system(size: 52, weight: .light, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.default, value: timerManager.formattedRemainingTime)

            HStack(spacing: 20) {
                Button {
                    timerManager.cancel()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title3.weight(.semibold))
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .disabled(!timerManager.isCancelEnabled)
                .accessibilityLabel("취소")

                Button {
                    timerManager.performPrimaryAction()
                } label: {
                    Image(systemName: timerManager.primaryActionIcon)
                        .font(.title2.weight(.semibold))
                        .frame(width: 64, height: 64)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .accessibilityLabel(primaryActionAccessibilityLabel)
            }
            .padding(.bottom, 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var primaryActionAccessibilityLabel: String {
        switch timerManager.phase {
        case .idle:
            "시작"
        case .running:
            "일시정지"
        case .paused:
            "재개"
        }
    }
}

#Preview("Compact") {
    RestTimerView()
        .environment(TimerManager())
}

#Preview("Expanded") {
    let manager = TimerManager()
    manager.isExpanded = true

    return RestTimerView()
        .environment(manager)
}
