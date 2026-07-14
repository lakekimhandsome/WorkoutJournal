//
//  RestTimerView.swift
//  WorkoutJournal
//

import SwiftUI

struct RestTimerView: View {
    @Environment(TimerManager.self) private var timerManager
    @Namespace private var timerNamespace

    var body: some View {
        GlassEffectContainer {
            Group {
                if timerManager.isExpanded {
                    expandedContent
                } else {
                    compactContent
                }
            }
        }
        .geometryGroup()
    }

    private var compactContent: some View {
        ZStack {
            // Match `.controlSize(.large)` circular glass button height.
            Button {} label: {
                Image(systemName: "square.and.pencil")
                    .font(.title3.weight(.semibold))
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .hidden()
            .accessibilityHidden(true)

            HStack(spacing: 10) {
                Button {
                    setExpanded(true)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "timer")
                            .foregroundStyle(.secondary)
                            .transition(.opacity)

                        timeLabel(font: .body.monospacedDigit().weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)

                Button {
                    timerManager.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("초기화")
            }
            .padding(.horizontal, 14)
        }
        .frame(maxWidth: 200)
        .glassEffect(.regular, in: .capsule)
        .glassEffectID("restTimer", in: timerNamespace)
        .matchedGeometryEffect(id: "restTimerChrome", in: timerNamespace)
    }

    private var expandedContent: some View {
        VStack(spacing: 16) {
            timeLabel(font: .largeTitle.monospacedDigit().weight(.semibold))

            HStack(spacing: 16) {
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
            .transition(.opacity.combined(with: .scale(0.9)))
        }
        .padding(16)
        .frame(maxWidth: 220)
        .glassEffect(.regular, in: .rect(cornerRadius: 22, style: .continuous))
        .glassEffectID("restTimer", in: timerNamespace)
        .matchedGeometryEffect(id: "restTimerChrome", in: timerNamespace)
    }

    private func timeLabel(font: Font) -> some View {
        Text(timerManager.formattedRemainingTime)
            .font(font)
            .contentTransition(.numericText())
            .matchedGeometryEffect(id: "restTimerTime", in: timerNamespace)
    }

    private func setExpanded(_ expanded: Bool) {
        withAnimation(.bouncy) {
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

#Preview {
    RestTimerView()
        .environment(TimerManager())
        .padding()
}
