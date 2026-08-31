//
//  SessionDetailView.swift
//  WorkoutJournal
//

import SwiftUI

struct SessionDetailView: View {
    @Binding var session: WorkoutSession
    @Environment(TimerManager.self) private var timerManager
    @Environment(CategoryStore.self) private var categoryStore
    @Environment(\.locale) private var locale
    @State private var newExerciseName = ""

    var body: some View {
        List {
            Section {
                ForEach($session.exercises) { $exercise in
                    ExerciseRow(exercise: $exercise) {
                        timerManager.startRestAfterSet()
                    } onDelete: {
                        session.exercises.removeAll { $0.id == exercise.id }
                    }
                }
            } header: {
                HStack {
                    Text("Exercises")

                    Spacer()

                    Text("\(session.exercises.count) exercises · \(totalSetCount) sets")
                        .monospacedDigit()
                        .textCase(nil)
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Menu {
                        Picker("Category", selection: $session.category) {
                            ForEach(availableCategories, id: \.self) { category in
                                Text(category)
                                    .tag(category)
                            }
                        }
                    } label: {
                        Label("Change Category", systemImage: "tag")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .menuIndicator(.hidden)
                .menuOrder(.fixed)
                .accessibilityLabel("More")
            }
        }
    }

    private var totalSetCount: Int {
        session.exercises.reduce(0) { $0 + $1.setCount }
    }

    private var availableCategories: [String] {
        guard !categoryStore.categories.contains(session.category) else {
            return categoryStore.categories
        }

        return session.category.isEmpty
            ? categoryStore.categories
            : [session.category] + categoryStore.categories
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
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField("Exercise Name", text: $exercise.name)
                    .fontWeight(.medium)

                Stepper {
                    Text("\(exercise.setCount) sets")
                        .font(.subheadline)
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

            if let setSummary {
                Label(setSummary, systemImage: "dumbbell.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            TextField("Add a note", text: $exercise.notes, axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1...3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Delete", role: .destructive, action: onDelete)
        }
    }

    private var setSummary: String? {
        var summaries: [(text: String, count: Int)] = []

        for set in exercise.sets {
            guard let text = set.displayText else { continue }

            if let index = summaries.firstIndex(where: { $0.text == text }) {
                summaries[index].count += 1
            } else {
                summaries.append((text, 1))
            }
        }

        guard !summaries.isEmpty else { return nil }

        return summaries
            .map { summary in
                summary.count > 1 ? "\(summary.text) × \(summary.count)" : summary.text
            }
            .joined(separator: "  ·  ")
    }
}

#Preview {
    @Previewable @State var session = MockData.sessions[0]

    NavigationStack {
        SessionDetailView(session: $session)
    }
    .environment(TimerManager())
    .environment(CategoryStore.shared)
}
