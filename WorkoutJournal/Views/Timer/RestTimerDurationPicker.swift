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

                ZStack {
                    DurationWheelPicker(hours: $hours, minutes: $minutes, seconds: $seconds)

                    HStack(spacing: 0) {
                        unitLabel("시간")
                        unitLabel("분")
                        unitLabel("초")
                    }
                    .allowsHitTesting(false)
                }
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

    private func unitLabel(_ unit: String) -> some View {
        Text(unit)
            .font(.headline)
            .offset(x: 22)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
    }
}

private struct DurationWheelPicker: UIViewRepresentable {
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(hours: $hours, minutes: $minutes, seconds: $seconds)
    }

    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        picker.selectRow(hours, inComponent: 0, animated: false)
        picker.selectRow(minutes, inComponent: 1, animated: false)
        picker.selectRow(seconds, inComponent: 2, animated: false)
        return picker
    }

    func updateUIView(_ picker: UIPickerView, context: Context) {
        context.coordinator.hours = $hours
        context.coordinator.minutes = $minutes
        context.coordinator.seconds = $seconds

        if picker.selectedRow(inComponent: 0) != hours {
            picker.selectRow(hours, inComponent: 0, animated: false)
        }
        if picker.selectedRow(inComponent: 1) != minutes {
            picker.selectRow(minutes, inComponent: 1, animated: false)
        }
        if picker.selectedRow(inComponent: 2) != seconds {
            picker.selectRow(seconds, inComponent: 2, animated: false)
        }
    }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var hours: Binding<Int>
        var minutes: Binding<Int>
        var seconds: Binding<Int>

        init(hours: Binding<Int>, minutes: Binding<Int>, seconds: Binding<Int>) {
            self.hours = hours
            self.minutes = minutes
            self.seconds = seconds
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int { 3 }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            component == 0 ? 24 : 60
        }

        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            "\(row)"
        }

        func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
            let width = pickerView.bounds.width
            return width > 0 ? width / 3 : 100
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            switch component {
            case 0: hours.wrappedValue = row
            case 1: minutes.wrappedValue = row
            default: seconds.wrappedValue = row
            }
        }
    }
}

#Preview {
    RestTimerDurationPicker(duration: 90) { _ in }
}
