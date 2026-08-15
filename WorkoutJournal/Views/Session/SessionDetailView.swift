//
//  SessionDetailView.swift
//  WorkoutJournal
//

import SwiftUI

struct SessionDetailView: View {
    @Binding var session: WorkoutSession
    @State private var newExerciseName = ""

    var body: some View {
        List {
            Section {
                Text(session.date, format: .dateTime.year().month().day().weekday())
                    .foregroundStyle(.secondary)
            }

            ForEach($session.exercises) { $exercise in
                Section {
                    Stepper(value: $exercise.setCount, in: 1...30) {
                        LabeledContent {
                            Text("\(exercise.setCount)")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        } label: {
                            TextField("운동 이름", text: $exercise.name)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("삭제", role: .destructive) {
                            session.exercises.removeAll { $0.id == exercise.id }
                        }
                    }

                    TextField("메모 남기기", text: $exercise.notes, axis: .vertical)
                        .lineLimit(1...4)
                }
            }

            Section {
                HStack {
                    TextField("운동 이름", text: $newExerciseName)
                        .onSubmit(addExercise)

                    Button("추가", action: addExercise)
                        .disabled(!canAddExercise)
                }
            }
        }
        .navigationTitle(session.title)
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
}
