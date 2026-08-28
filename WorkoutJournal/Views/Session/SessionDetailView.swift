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
                    Stepper {
                        LabeledContent {
                            Text("\(exercise.setCount)")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        } label: {
                            TextField("Exercise Name", text: $exercise.name)
                        }
                    } onIncrement: {
                        guard exercise.setCount < 30 else { return }
                        exercise.setCount += 1
                        timerManager.startRestAfterSet()
                    } onDecrement: {
                        guard exercise.setCount > 1 else { return }
                        exercise.setCount -= 1
                    }
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("Delete", role: .destructive) {
                            session.exercises.removeAll { $0.id == exercise.id }
                        }
                    }

                    TextField("Add a note", text: $exercise.notes, axis: .vertical)
                        .lineLimit(1...4)
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

#Preview {
    @Previewable @State var session = MockData.sessions[0]

    NavigationStack {
        SessionDetailView(session: $session)
    }
    .environment(TimerManager())
}
