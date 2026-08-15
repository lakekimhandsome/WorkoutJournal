//
//  WorkoutSession.swift
//  WorkoutJournal
//

import Foundation

struct WorkoutSession: Identifiable, Hashable {
    let id: UUID
    let date: Date
    var notes: String
    var exercises: [Exercise]

    static func new() -> WorkoutSession {
        WorkoutSession(
            id: UUID(),
            date: .now,
            notes: "",
            exercises: []
        )
    }
}

enum MockData {
    static let sessions: [WorkoutSession] = [
        WorkoutSession(
            id: UUID(),
            date: .now.addingTimeInterval(-86_400),
            notes: "",
            exercises: [
                Exercise(
                    name: "덤벨 슈러그",
                    notes: "38 12",
                    sets: [
                        .new(weight: 38, reps: 12),
                        .new(weight: 38, reps: 12),
                    ]
                ),
                Exercise(name: "턱걸이"),
                Exercise(
                    name: "티바로우",
                    notes: "30 10",
                    sets: [
                        .new(weight: 30, reps: 10),
                        .new(),
                    ]
                ),
                Exercise(
                    name: "원암 랫풀다운",
                    notes: "30 9",
                    sets: [
                        .new(weight: 30, reps: 9),
                        .new(weight: 30, reps: 9),
                    ]
                ),
                Exercise(
                    name: "사이드 라잉 래터럴 레이즈",
                    notes: "6 19",
                    sets: (0..<10).map { _ in WorkoutSet.new(weight: 6, reps: 19) }
                ),
            ]
        ),
        WorkoutSession(
            id: UUID(),
            date: .now.addingTimeInterval(-172_800),
            notes: "",
            exercises: [
                Exercise(
                    id: UUID(),
                    name: "스쿼트",
                    notes: "",
                    sets: (0..<5).map { _ in WorkoutSet.new(weight: 100, reps: 5) }
                ),
                Exercise(
                    id: UUID(),
                    name: "루마니안 데드리프트",
                    notes: "",
                    sets: (0..<3).map { _ in WorkoutSet.new(weight: 80, reps: 8) }
                ),
                Exercise(
                    id: UUID(),
                    name: "레그 프레스",
                    notes: "",
                    sets: (0..<3).map { _ in WorkoutSet.new(weight: nil, reps: 12) }
                ),
            ]
        ),
        WorkoutSession(
            id: UUID(),
            date: .now.addingTimeInterval(-259_200),
            notes: "",
            exercises: [
                Exercise(
                    id: UUID(),
                    name: "케틀벨 스윙",
                    notes: "",
                    sets: (0..<5).map { _ in WorkoutSet.new(weight: nil, reps: 15) }
                ),
                Exercise(
                    id: UUID(),
                    name: "버피",
                    notes: "",
                    sets: (0..<4).map { _ in WorkoutSet.new(weight: nil, reps: 10) }
                ),
                Exercise(
                    id: UUID(),
                    name: "플랭크",
                    notes: "45초",
                    sets: (0..<3).map { _ in WorkoutSet.new() }
                ),
            ]
        ),
    ]
}
