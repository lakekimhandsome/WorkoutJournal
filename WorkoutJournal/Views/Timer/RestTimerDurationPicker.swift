//
//  RestTimerDurationPicker.swift
//  WorkoutJournal
//

import SwiftUI
import UIKit

struct RestTimerDurationPicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var minutes: Int
    @State private var seconds: Int

    private let onConfirm: (TimeInterval) -> Void

    private var selectedDuration: TimeInterval {
        TimeInterval(minutes * 60 + seconds)
    }

    init(duration: TimeInterval, onConfirm: @escaping (TimeInterval) -> Void) {
        let total = min(Int(max(0, duration.rounded(.up))), 59 * 60 + 59)
        _minutes = State(initialValue: total / 60)
        _seconds = State(initialValue: total % 60)
        self.onConfirm = onConfirm
    }

    var body: some View {
        NavigationStack {
            VStack {
                Spacer(minLength: 0)

                ZStack {
                    DurationWheelPicker(minutes: $minutes, seconds: $seconds)

                    HStack(spacing: 0) {
                        unitLabel("분")
                        unitLabel("초")
                    }
                    .allowsHitTesting(false)
                }
                .frame(width: 240, height: 216)

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
    @Binding var minutes: Int
    @Binding var seconds: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(minutes: $minutes, seconds: $seconds)
    }

    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        picker.selectRow(minutes, inComponent: 0, animated: false)
        picker.selectRow(seconds, inComponent: 1, animated: false)
        return picker
    }

    func updateUIView(_ picker: UIPickerView, context: Context) {
        context.coordinator.minutes = $minutes
        context.coordinator.seconds = $seconds

        if picker.selectedRow(inComponent: 0) != minutes {
            picker.selectRow(minutes, inComponent: 0, animated: false)
        }
        if picker.selectedRow(inComponent: 1) != seconds {
            picker.selectRow(seconds, inComponent: 1, animated: false)
        }
    }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var minutes: Binding<Int>
        var seconds: Binding<Int>

        init(minutes: Binding<Int>, seconds: Binding<Int>) {
            self.minutes = minutes
            self.seconds = seconds
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int { 2 }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            60
        }

        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            "\(row)"
        }

        func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
            pickerView.bounds.width / 2
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            if component == 0 {
                minutes.wrappedValue = row
            } else {
                seconds.wrappedValue = row
            }
        }
    }
}

#Preview {
    RestTimerDurationPicker(duration: 90) { _ in }
}
