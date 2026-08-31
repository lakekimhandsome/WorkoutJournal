//
//  SessionDetailView.swift
//  WorkoutJournal
//

import SwiftUI

struct SessionDetailView: View {
    @Binding var session: WorkoutSession
    @Binding var isKeyboardPresented: Bool
    @Environment(TimerManager.self) private var timerManager
    @Environment(CategoryStore.self) private var categoryStore
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.locale) private var locale
    @State private var newExerciseName = ""
    @State private var selectedPreviousSessionID: WorkoutSession.ID?
    @State private var exerciseNotePrompts: [Exercise.ID: String] = [:]
    @FocusState private var isTextInputFocused: Bool

    var body: some View {
        List {
            Section {
                ForEach($session.exercises) { $exercise in
                    ExerciseRow(
                        exercise: $exercise,
                        notePrompt: exerciseNotePrompts[exercise.id],
                        isTextInputFocused: $isTextInputFocused
                    ) {
                        timerManager.startRestAfterSet()
                    } onDelete: {
                        let id = exercise.id
                        session.exercises.removeAll { $0.id == id }
                        exerciseNotePrompts[id] = nil
                    }
                }
            } header: {
                Text("Exercises")
            }

            Section {
                HStack {
                    TextField("Exercise Name", text: $newExerciseName)
                        .focused($isTextInputFocused)
                        .submitLabel(.done)
                        .onSubmit(addExercise)

                    Button("Add", action: addExercise)
                        .disabled(!canAddExercise)
                }
            }

            if let displayedPreviousSession {
                Section {
                    if !displayedPreviousSession.notes.isEmpty {
                        Text(displayedPreviousSession.notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if previousSessions.count > 1 {
                        PreviousSessionNavigation(
                            position: selectedPreviousSessionIndex + 1,
                            total: previousSessions.count,
                            canShowOlder: selectedPreviousSessionIndex < previousSessions.count - 1,
                            canShowNewer: selectedPreviousSessionIndex > 0,
                            onShowOlder: showOlderSession,
                            onShowNewer: showNewerSession
                        )
                    }

                    ForEach(displayedPreviousSession.exercises) { exercise in
                        Button {
                            addExercise(from: exercise)
                        } label: {
                            PreviousExerciseRow(exercise: exercise)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text(
                        displayedPreviousSession.date,
                        format: .dateTime.year().month().day().weekday()
                    )
                    .textCase(nil)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(session.date.formatted(.dateTime.year().month().day().weekday().locale(locale)))
        .navigationSubtitle(session.category)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: session.category) {
            selectedPreviousSessionID = nil
        }
        .onChange(of: isTextInputFocused) { _, isFocused in
            isKeyboardPresented = isFocused
        }
        .onDisappear {
            isKeyboardPresented = false
        }
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

    private var previousSessions: [WorkoutSession] {
        sessionStore.sessions
            .filter { candidate in
                candidate.id != session.id
                    && candidate.category == session.category
                    && candidate.date < session.date
            }
            .sorted { lhs, rhs in
                if lhs.date != rhs.date {
                    return lhs.date > rhs.date
                }

                return lhs.id.uuidString < rhs.id.uuidString
            }
    }

    private var selectedPreviousSessionIndex: Int {
        guard let selectedPreviousSessionID else { return 0 }
        return previousSessions.firstIndex { $0.id == selectedPreviousSessionID } ?? 0
    }

    private var displayedPreviousSession: WorkoutSession? {
        previousSessions.indices.contains(selectedPreviousSessionIndex)
            ? previousSessions[selectedPreviousSessionIndex]
            : nil
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
        isTextInputFocused = false
    }

    private func addExercise(from previousExercise: Exercise) {
        let exercise = Exercise(name: previousExercise.name)
        let note = previousExercise.notes.trimmingCharacters(in: .whitespacesAndNewlines)

        session.exercises.append(exercise)

        if !note.isEmpty {
            exerciseNotePrompts[exercise.id] = note
        }
    }

    private func showOlderSession() {
        let index = selectedPreviousSessionIndex + 1
        guard previousSessions.indices.contains(index) else { return }

        withAnimation(.snappy) {
            selectedPreviousSessionID = previousSessions[index].id
        }
    }

    private func showNewerSession() {
        let index = selectedPreviousSessionIndex - 1
        guard previousSessions.indices.contains(index) else { return }

        withAnimation(.snappy) {
            selectedPreviousSessionID = previousSessions[index].id
        }
    }
}

private struct PreviousExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(exercise.name)
                    .fontWeight(.medium)

                Spacer()

                Text("\(exercise.setCount) sets")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)

                Image(systemName: "plus.circle")
                    .foregroundStyle(.tint)
            }

            if let setSummary = exerciseSetSummary(for: exercise) {
                Label(setSummary, systemImage: "dumbbell.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !exercise.notes.isEmpty {
                Text(exercise.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
        .accessibilityElement(children: .combine)
    }
}

private struct PreviousSessionNavigation: View {
    let position: Int
    let total: Int
    let canShowOlder: Bool
    let canShowNewer: Bool
    let onShowOlder: () -> Void
    let onShowNewer: () -> Void

    var body: some View {
        HStack {
            Button("Older", systemImage: "chevron.backward", action: onShowOlder)
                .labelStyle(.iconOnly)
                .disabled(!canShowOlder)

            Spacer()

            Text("\(position)/\(total)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()

            Spacer()

            Button("Newer", systemImage: "chevron.forward", action: onShowNewer)
                .labelStyle(.iconOnly)
                .disabled(!canShowNewer)
        }
        .buttonStyle(.borderless)
        .listRowSeparator(.hidden)
    }
}

private struct ExerciseRow: View {
    @Binding var exercise: Exercise
    let notePrompt: String?
    let isTextInputFocused: FocusState<Bool>.Binding
    var onSetIncremented: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField("Exercise Name", text: $exercise.name)
                    .fontWeight(.medium)
                    .focused(isTextInputFocused)

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
                    guard exercise.setCount > 0 else { return }
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

            TextField(
                notePrompt ?? String(localized: "Add a note"),
                text: $exercise.notes,
                axis: .vertical
            )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1...3)
                .fixedSize(horizontal: false, vertical: true)
                .focused(isTextInputFocused)
        }
        .padding(.vertical, 2)
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Delete", role: .destructive, action: onDelete)
        }
    }

    private var setSummary: String? {
        exerciseSetSummary(for: exercise)
    }
}

private func exerciseSetSummary(for exercise: Exercise) -> String? {
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

#Preview {
    @Previewable @State var session = MockData.sessions[0]
    @Previewable @State var isKeyboardPresented = false

    NavigationStack {
        SessionDetailView(
            session: $session,
            isKeyboardPresented: $isKeyboardPresented
        )
    }
    .environment(TimerManager())
    .environment(CategoryStore.shared)
    .environment(SessionStore.shared)
}
