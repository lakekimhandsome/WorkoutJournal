//
//  RestTimerDurationPicker.swift
//  WorkoutJournal
//

import SwiftUI

struct RestTimerDurationPicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var duration: TimeInterval

    private let onConfirm: (TimeInterval) -> Void

    init(duration: TimeInterval, onConfirm: @escaping (TimeInterval) -> Void) {
        let total = min(max(0, duration.rounded(.up)), 59 * 60 + 59)
        _duration = State(initialValue: total)
        self.onConfirm = onConfirm
    }

    var body: some View {
        NavigationStack {
            MinutesSecondsPicker(duration: $duration)
                .navigationTitle("Duration")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel) {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button(role: .confirm) {
                            onConfirm(duration)
                            dismiss()
                        }
                        .disabled(duration < 1)
                    }
                }
        }
        .presentationDetents([.medium])
    }
}

private struct TimerPickerMetrics: Equatable {
    var wheelHeight: CGFloat
    var numberWidth: CGFloat
    var labelWidth: CGFloat
    var labelGap: CGFloat
    var numberFont: Font
    var labelFont: Font

    init(
        wheelHeight: CGFloat = 216,
        numberWidth: CGFloat = 56,
        labelWidth: CGFloat = 46,
        labelGap: CGFloat = 6,
        numberFont: Font = .system(size: 23),
        labelFont: Font = .system(size: 17, weight: .semibold)
    ) {
        self.wheelHeight = wheelHeight
        self.numberWidth = numberWidth
        self.labelWidth = labelWidth
        self.labelGap = labelGap
        self.numberFont = numberFont
        self.labelFont = labelFont
    }

    static let clock = TimerPickerMetrics()

    var rowWidth: CGFloat { numberWidth + labelGap + labelWidth }

    /// Label centre, measured from the column centre, so it sits
    /// in the trailing slot of a centred number + gap + label row.
    var labelOffset: CGFloat { (numberWidth + labelGap) / 2 }
}

private struct MinutesSecondsPicker: View {
    @Binding var duration: TimeInterval

    private let minuteRange: ClosedRange<Int>
    private let secondStep: Int
    private let metrics: TimerPickerMetrics

    @State private var minutes: Int
    @State private var seconds: Int

    init(
        duration: Binding<TimeInterval>,
        minuteRange: ClosedRange<Int> = 0...59,
        secondStep: Int = 1,
        metrics: TimerPickerMetrics = .clock
    ) {
        self._duration = duration
        self.minuteRange = minuteRange
        self.secondStep = max(1, secondStep)
        self.metrics = metrics

        let total = max(0, Int(duration.wrappedValue.rounded()))
        _minutes = State(initialValue: min(total / 60, minuteRange.upperBound))
        _seconds = State(initialValue: (total % 60) / self.secondStep * self.secondStep)
    }

    private var minuteValues: [Int] { Array(minuteRange) }
    private var secondValues: [Int] { Array(stride(from: 0, to: 60, by: secondStep)) }

    var body: some View {
        HStack(spacing: 0) {
            WheelColumn(
                values: minuteValues,
                label: "min",
                unitName: "Minutes",
                metrics: metrics,
                selection: $minutes
            )
            WheelColumn(
                values: secondValues,
                label: "sec",
                unitName: "Seconds",
                metrics: metrics,
                selection: $seconds
            )
        }
        .frame(height: metrics.wheelHeight)
        .sensoryFeedback(.selection, trigger: minutes)
        .sensoryFeedback(.selection, trigger: seconds)
        .onChange(of: minutes) { _, _ in pushOut() }
        .onChange(of: seconds) { _, _ in pushOut() }
        .onChange(of: duration) { _, _ in pullIn() }
    }

    private func pushOut() {
        let new = TimeInterval(minutes * 60 + seconds)
        if abs(new - duration) >= 0.5 { duration = new }
    }

    private func pullIn() {
        let total = max(0, Int(duration.rounded()))
        guard total != minutes * 60 + seconds else { return }
        let m = min(total / 60, minuteRange.upperBound)
        let s = (total % 60) / secondStep * secondStep
        if minutes != m { minutes = m }
        if seconds != s { seconds = s }
    }
}

private struct WheelColumn: View {
    let values: [Int]
    let label: LocalizedStringKey
    let unitName: LocalizedStringKey
    let metrics: TimerPickerMetrics
    @Binding var selection: Int

    var body: some View {
        Picker(selection: $selection) {
            ForEach(values, id: \.self) { value in
                Text(String(value))
                    .font(metrics.numberFont)
                    .monospacedDigit()
                    .frame(width: metrics.numberWidth, alignment: .trailing)
                    .padding(.trailing, metrics.labelGap + metrics.labelWidth)
                    .tag(value)
            }
        } label: {
            Text(unitName)
        }
        .labelsHidden()
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .center) {
            Text(label)
                .font(metrics.labelFont)
                .frame(width: metrics.labelWidth, alignment: .leading)
                .offset(x: metrics.labelOffset)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .accessibilityLabel(unitName)
        .accessibilityValue("\(selection)")
    }
}

#Preview {
    RestTimerDurationPicker(duration: 90) { _ in }
}
