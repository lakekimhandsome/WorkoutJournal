//
//  SessionDetailView.swift
//  WorkoutJournal
//

import SwiftUI

struct SessionDetailView: View {
    @Binding var session: WorkoutSession
    @Environment(TimerManager.self) private var timerManager
    @Environment(\.locale) private var locale
    @State private var newExerciseName = ""

    var body: some View {
        List {
            ForEach($session.exercises) { $exercise in
                Section {
                    ExerciseRow(exercise: $exercise) {
                        timerManager.startRestAfterSet()
                    } onDelete: {
                        session.exercises.removeAll { $0.id == exercise.id }
                    }
                }
            }

            Section {
                HStack {
                    TextField("Exercise Name", text: $newExerciseName)
                        .onSubmit(addExercise)

                    Button("Add", action: addExercise)
                        .disabled(!canAddExercise)
                }
            }
        }
        .navigationTitle(session.date.formatted(.dateTime.year().month().day().weekday().locale(locale)))
        .navigationSubtitle(session.category)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var canAddExercise: Bool {
        !newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addExercise() {
        let name = newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        session.exercises.append(Exercise(name: name))
        newExerciseName = ""
    }
}

private struct ExerciseRow: View {
    @Binding var exercise: Exercise
    var onSetIncremented: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                TextField("Exercise Name", text: $exercise.name)

                Stepper {
                    Text("\(exercise.setCount)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                } onIncrement: {
                    guard exercise.setCount < 30 else { return }
                    exercise.setCount += 1
                    onSetIncremented()
                } onDecrement: {
                    guard exercise.setCount > 1 else { return }
                    exercise.setCount -= 1
                }
                .fixedSize()
            }

            TextField("Add a note", text: $exercise.notes, axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1...4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}

#Preview {
    @Previewable @State var session = MockData.sessions[0]

    NavigationStack {
        SessionDetailView(session: $session)
    }
    .environment(TimerManager())
}
