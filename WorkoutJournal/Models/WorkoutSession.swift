//
//  WorkoutSession.swift
//  WorkoutJournal
//

import Foundation

struct WorkoutSession: Identifiable, Hashable {
    let id: UUID
    var title: String
    let date: Date
    var notes: String

    static func new() -> WorkoutSession {
        WorkoutSession(
            id: UUID(),
            title: "새 세션",
            date: .now,
            notes: ""
        )
    }
}

enum MockData {
    static let sessions: [WorkoutSession] = [
        WorkoutSession(
            id: UUID(),
            title: "상체 근력",
            date: .now.addingTimeInterval(-86_400),
            notes: """
            벤치프레스 80kg · 5×5
            오버헤드 프레스 50kg · 3×8
            풀업 · 3세트
            """
        ),
        WorkoutSession(
            id: UUID(),
            title: "하체 근력",
            date: .now.addingTimeInterval(-172_800),
            notes: """
            스쿼트 100kg · 5×5
            루마니안 데드리프트 80kg · 3×8
            레그 프레스 · 3×12
            """
        ),
        WorkoutSession(
            id: UUID(),
            title: "전신 컨디셔닝",
            date: .now.addingTimeInterval(-259_200),
            notes: """
            케틀벨 스윙 · 5×15
            버피 · 4×10
            플랭크 · 3×45초
            """
        ),
    ]
}
