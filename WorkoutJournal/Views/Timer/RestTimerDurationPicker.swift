//
//  RestTimerDurationPicker.swift
//  WorkoutJournal
//

import SwiftUI
import UIKit

struct RestTimerDurationPicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var hours: Int
    @State private var minutes: Int
    @State private var seconds: Int

    private let onConfirm: (TimeInterval) -> Void

    private var selectedDuration: TimeInterval {
        TimeInterval(hours * 3600 + minutes * 60 + seconds)
    }

    init(duration: TimeInterval, onConfirm: @escaping (TimeInterval) -> Void) {
        let total = Int(max(0, duration.rounded(.up)))
        _hours = State(initialValue: min(23, total / 3600))
        _minutes = State(initialValue: (total % 3600) / 60)
        _seconds = State(initialValue: total % 60)
        self.onConfirm = onConfirm
    }

    var body: some View {
        NavigationStack {
            VStack {
                Spacer(minLength: 0)
                DurationWheelPicker(hours: $hours, minutes: $minutes, seconds: $seconds)
                    .frame(height: 216)
                    .padding(.horizontal, 8)
                Spacer(minLength: 0)
            }
            .navigationTitle("시간")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        onConfirm(selectedDuration)
                        dismiss()
                    }
                    .disabled(selectedDuration < 1)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private enum DurationWheelLayout {
    static let spacing: CGFloat = 6
    static let units = ["시간", "분", "초"]
    static let unitFont = UIFont.preferredFont(forTextStyle: .headline)
    static let numberFont = UIFont.preferredFont(forTextStyle: .title2)

    static var numberWidth: CGFloat {
        ceil(("59" as NSString).size(withAttributes: [.font: numberFont]).width)
    }

    static func unitWidth(for component: Int) -> CGFloat {
        ceil((units[component] as NSString).size(withAttributes: [.font: unitFont]).width)
    }

    static func groupWidth(for component: Int) -> CGFloat {
        numberWidth + spacing + unitWidth(for: component)
    }
}

private struct DurationWheelPicker: UIViewRepresentable {
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int

    func makeUIView(context: Context) -> ClockStyleDurationPickerView {
        let picker = ClockStyleDurationPickerView()
        picker.select(hours: hours, minutes: minutes, seconds: seconds, animated: false)
        return picker
    }

    func updateUIView(_ picker: ClockStyleDurationPickerView, context: Context) {
        picker.onChange = { hours, minutes, seconds in
            self.hours = hours
            self.minutes = minutes
            self.seconds = seconds
        }

        if picker.hours != hours || picker.minutes != minutes || picker.seconds != seconds {
            picker.select(hours: hours, minutes: minutes, seconds: seconds, animated: false)
        }
    }
}

private final class ClockStyleDurationPickerView: UIPickerView, UIPickerViewDataSource, UIPickerViewDelegate {
    var hours = 0
    var minutes = 0
    var seconds = 0
    var onChange: ((Int, Int, Int) -> Void)?

    private let unitLabels: [UILabel] = DurationWheelLayout.units.map { text in
        let label = UILabel()
        label.text = text
        label.font = DurationWheelLayout.unitFont
        label.textColor = .label
        label.isAccessibilityElement = false
        return label
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        dataSource = self
        delegate = self
        unitLabels.forEach { addSubview($0) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func select(hours: Int, minutes: Int, seconds: Int, animated: Bool) {
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
        selectRow(hours, inComponent: 0, animated: animated)
        selectRow(minutes, inComponent: 1, animated: animated)
        selectRow(seconds, inComponent: 2, animated: animated)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        unitLabels.forEach { bringSubviewToFront($0) }
        layoutUnitLabels()
    }

    private func layoutUnitLabels() {
        for component in 0..<3 {
            let label = unitLabels[component]
            label.font = DurationWheelLayout.unitFont
            label.sizeToFit()

            let column = columnFrame(for: component)
            let groupWidth = DurationWheelLayout.groupWidth(for: component)
            let groupLeading = column.minX + (column.width - groupWidth) / 2

            label.frame.origin = CGPoint(
                x: groupLeading + DurationWheelLayout.numberWidth + DurationWheelLayout.spacing,
                y: bounds.midY - label.bounds.height / 2
            )
        }
    }

    private func columnFrame(for component: Int) -> CGRect {
        let wheels = subviews.filter { view in
            view.frame.height > bounds.height * 0.8
                && view.frame.width < bounds.width * 0.5
                && unitLabels.allSatisfy { $0 !== view }
        }
        .sorted { $0.frame.minX < $1.frame.minX }

        if wheels.count >= 3 {
            return wheels[component].frame
        }

        let widths = (0..<3).map { rowSize(forComponent: $0).width }
        let total = widths.reduce(0, +)
        let start = (bounds.width - total) / 2
        let x = start + widths.prefix(component).reduce(0, +)
        return CGRect(x: x, y: 0, width: widths[component], height: bounds.height)
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 3 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        component == 0 ? 24 : 60
    }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        let width = pickerView.bounds.width
        return width > 0 ? floor(width / 3) : 100
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let rowView = (view as? DurationPickerRowView) ?? DurationPickerRowView()
        rowView.configure(row: row, component: component)
        return rowView
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0: hours = row
        case 1: minutes = row
        default: seconds = row
        }
        onChange?(hours, minutes, seconds)
    }
}

private final class DurationPickerRowView: UIView {
    private let label = UILabel()
    private var component = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = DurationWheelLayout.numberFont
        label.textAlignment = .right
        label.adjustsFontForContentSizeCategory = true
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(row: Int, component: Int) {
        self.component = component
        label.text = "\(row)"
        label.accessibilityLabel = "\(row) \(DurationWheelLayout.units[component])"
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let groupWidth = DurationWheelLayout.groupWidth(for: component)
        let groupLeading = (bounds.width - groupWidth) / 2
        label.frame = CGRect(
            x: groupLeading,
            y: 0,
            width: DurationWheelLayout.numberWidth,
            height: bounds.height
        )
    }
}

#Preview {
    RestTimerDurationPicker(duration: 90) { _ in }
}
