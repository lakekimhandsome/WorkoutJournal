//
//  RestTimerDurationPicker.swift
//  WorkoutJournal
//

import SwiftUI

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
            HStack {
                Picker("시간", selection: $hours) {
                    ForEach(0..<24, id: \.self) { value in
                        Text("\(value)시간").tag(value)
                    }
                }

                Picker("분", selection: $minutes) {
                    ForEach(0..<60, id: \.self) { value in
                        Text("\(value)분").tag(value)
                    }
                }

                Picker("초", selection: $seconds) {
                    ForEach(0..<60, id: \.self) { value in
                        Text("\(value)초").tag(value)
                    }
                }
            }
            .pickerStyle(.wheel)
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

#Preview {
    RestTimerDurationPicker(duration: 90) { _ in }
}
