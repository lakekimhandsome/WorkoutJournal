import Foundation
import Observation
import Supabase

@Observable
@MainActor
final class SessionStore {
    static let shared = SessionStore()

    var sessions: [WorkoutSession] = [] {
        didSet {
            guard !suppressPersist else { return }
            schedulePersist()
        }
    }

    var hasLatestExercise: Bool {
        latestExerciseLocation != nil
    }

    private var currentUserID: UUID?
    private var suppressPersist = false
    private var persistTask: Task<Void, Never>?

    func resetLocal() {
        persistTask?.cancel()
        persistTask = nil
        currentUserID = nil
        suppressPersist = true
        sessions = []
        suppressPersist = false
    }

    func loadRemote(userID: UUID) async {
        currentUserID = userID
        persistTask?.cancel()

        do {
            let rows: [WorkoutJournalSessionRecord] = try await SupabaseService.client
                .from("workoutjournal_sessions")
                .select()
                .eq("user_id", value: userID)
                .order("occurred_at", ascending: false)
                .execute()
                .value

            suppressPersist = true
            sessions = rows.map(\.session)
            suppressPersist = false
        } catch {
            suppressPersist = true
            sessions = []
            suppressPersist = false
        }
    }

    func remove(id: UUID) {
        sessions.removeAll { $0.id == id }
        Task {
            try? await SupabaseService.client
                .from("workoutjournal_sessions")
                .delete()
                .eq("id", value: id)
                .execute()
        }
    }

    @discardableResult
    func addSetsToLatestExercise(count: Int) -> Int {
        guard count > 0, let location = latestExerciseLocation else { return 0 }

        var sessions = sessions
        let currentCount = sessions[location.session].exercises[location.exercise].setCount
        let newCount = min(30, currentCount + count)
        let added = newCount - currentCount
        guard added > 0 else { return 0 }

        sessions[location.session].exercises[location.exercise].setCount = newCount
        self.sessions = sessions
        return added
    }

    private func schedulePersist() {
        guard currentUserID != nil else { return }
        persistTask?.cancel()
        persistTask = Task {
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            await persistAll()
        }
    }

    private func persistAll() async {
        guard let currentUserID else { return }

        let records = sessions.map {
            WorkoutJournalSessionRecord(session: $0, userID: currentUserID)
        }

        do {
            try await SupabaseService.client
                .from("workoutjournal_sessions")
                .upsert(records)
                .execute()
        } catch {
            return
        }
    }

    private var latestExerciseLocation: (session: Int, exercise: Int)? {
        guard let sessionIndex = latestSessionIndex else { return nil }
        guard let exerciseIndex = sessions[sessionIndex].exercises.indices.last else { return nil }
        return (sessionIndex, exerciseIndex)
    }

    private var latestSessionIndex: Int? {
        sessions.enumerated()
            .max { lhs, rhs in
                if lhs.element.date != rhs.element.date {
                    return lhs.element.date < rhs.element.date
                }
                return lhs.offset > rhs.offset
            }?
            .offset
    }
}

private struct WorkoutJournalSessionRecord: Codable {
    let id: UUID
    let userID: UUID
    let occurredAt: Date
    let notes: String
    let exercises: [Exercise]
    let updatedAt: Date

    var session: WorkoutSession {
        WorkoutSession(id: id, date: occurredAt, notes: notes, exercises: exercises)
    }

    init(session: WorkoutSession, userID: UUID) {
        id = session.id
        self.userID = userID
        occurredAt = session.date
        notes = session.notes
        exercises = session.exercises
        updatedAt = .now
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case occurredAt = "occurred_at"
        case notes
        case exercises
        case updatedAt = "updated_at"
    }
}
