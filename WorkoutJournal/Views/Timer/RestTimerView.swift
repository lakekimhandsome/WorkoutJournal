//
//  RestTimerView.swift
//  WorkoutJournal 
//

import SwiftUI

struct RestTimerView: View {
    @Environment(TimerManager.self) private var timerManager

    private var isExpanded: Bool { timerManager.isExpanded }

    var body: some View {
        // Shared sampling keeps panel glass and nested glass buttons in one system.
        GlassEffectContainer {
            ZStack {
                // Keeps compact height aligned with `.controlSize(.large)` glass circle.
                largeControlSizeReference

                VStack(spacing: isExpanded ? 16 : 0) {
                    header
                    controls
                }
                // Insets leave room for the system glass button press scale.
                .padding(.horizontal, isExpanded ? 20 : 14)
                .padding(.vertical, isExpanded ? 20 : 0)
            }
            .frame(maxWidth: isExpanded ? 228 : 200)
            .glassEffect(
                .regular,
                in: .rect(cornerRadius: isExpanded ? 26 : 100, style: .continuous)
            )
        }
        .geometryGroup()
        .animation(.snappy, value: isExpanded)
    }

    // MARK: - Shared layout

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "timer")
                .foregroundStyle(.secondary)
                .opacity(isExpanded ? 0 : 1)
                .scaleEffect(isExpanded ? 0.85 : 1)
                .frame(width: isExpanded ? 0 : 20)
                .clipped(when: !isExpanded)
                .accessibilityHidden(isExpanded)

            Button {
                if !isExpanded {
                    setExpanded(true)
                }
            } label: {
                Text(timerManager.formattedRemainingTime)
                    .font(
                        isExpanded
                            ? .largeTitle.monospacedDigit().weight(.semibold)
                            : .body.monospacedDigit().weight(.semibold)
                    )
                    .frame(maxWidth: .infinity, alignment: isExpanded ? .center : .leading)
                    .contentTransition(.numericText())
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("휴식 타이머 \(timerManager.formattedRemainingTime)")
            .accessibilityHint(isExpanded ? "" : "탭하여 확장")

            Button {
                timerManager.reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(isExpanded ? 0 : 1)
            .scaleEffect(isExpanded ? 0.85 : 1)
            .frame(width: isExpanded ? 0 : 28)
            .clipped(when: !isExpanded)
            .allowsHitTesting(!isExpanded)
            .accessibilityLabel("초기화")
            .accessibilityHidden(isExpanded)
        }
    }

    private var controls: some View {
        HStack(spacing: 20) {
            Button {
                timerManager.cancel()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .disabled(!timerManager.isCancelEnabled)
            .accessibilityLabel("취소")

            Button {
                timerManager.performPrimaryAction()
            } label: {
                Image(systemName: timerManager.primaryActionIcon)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .accessibilityLabel(primaryActionAccessibilityLabel)
        }
        .opacity(isExpanded ? 1 : 0)
        .scaleEffect(isExpanded ? 1 : 0.92, anchor: .top)
        .frame(height: isExpanded ? nil : 0, alignment: .top)
        // Clip only while collapsed so compact stays tidy;
        // never clip when expanded — system press scale must not be cut off.
        .clipped(when: !isExpanded)
        .allowsHitTesting(isExpanded)
        .accessibilityHidden(!isExpanded)
    }

    private var largeControlSizeReference: some View {
        Button {} label: {
            Image(systemName: "square.and.pencil")
                .font(.title3.weight(.semibold))
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.large)
        .hidden()
        .accessibilityHidden(true)
    }

    private func setExpanded(_ expanded: Bool) {
        withAnimation(.snappy) {
            timerManager.isExpanded = expanded
        }
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

private extension View {
    @ViewBuilder
    func clipped(when condition: Bool) -> some View {
        if condition {
            clipped()
        } else {
            self
        }
    }
}

#Preview {
    RestTimerView()
        .environment(TimerManager())
        .padding()
}
