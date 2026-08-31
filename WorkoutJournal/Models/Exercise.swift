//
//  Exercise.swift
//  WorkoutJournal
//

import Foundation

struct Exercise: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var notes: String
    var sets: [WorkoutSet]

    var setCount: Int {
        get { sets.count }
        set { adjustSetCount(to: newValue) }
    }

    init(
        id: UUID = UUID(),
        name: String,
        notes: String = "",
        sets: [WorkoutSet] = []
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.sets = sets
    }

    mutating func adjustSetCount(to newCount: Int) {
        let newCount = max(0, newCount)
        while sets.count < newCount {
            sets.append(.new(weight: sets.last?.weight, reps: sets.last?.reps))
        }
        if sets.count > newCount {
            sets.removeLast(sets.count - newCount)
        }
    }
}
