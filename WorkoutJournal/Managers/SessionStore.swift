import Foundation
import Observation

@Observable
@MainActor
final class SessionStore {
    static let shared = SessionStore()

    var sessions: [WorkoutSession] = MockData.sessions

    var hasLatestExercise: Bool {
        latestExerciseLocation != nil
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
