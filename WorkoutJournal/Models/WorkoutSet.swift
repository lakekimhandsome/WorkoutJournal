//
//  WorkoutSet.swift
//  WorkoutJournal
//

import Foundation

struct WorkoutSet: Identifiable, Hashable, Codable {
    let id: UUID
    var weight: Double?
    var reps: Int?

    static func new(weight: Double? = nil, reps: Int? = nil) -> WorkoutSet {
        WorkoutSet(id: UUID(), weight: weight, reps: reps)
    }

    var displayText: String? {
        switch (weight, reps) {
        case let (weight?, reps?):
            "\(Self.formattedWeight(weight)) kg / \(reps) reps"
        case let (weight?, nil):
            "\(Self.formattedWeight(weight)) kg"
        case let (nil, reps?):
            "\(reps) reps"
        case (nil, nil):
            nil
        }
    }

    private static func formattedWeight(_ weight: Double) -> String {
        weight.formatted(.number.precision(.fractionLength(0...2)))
    }
}
