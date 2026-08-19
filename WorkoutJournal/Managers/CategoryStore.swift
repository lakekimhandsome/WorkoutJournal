import Foundation
import Observation
import Supabase

@Observable
@MainActor
final class CategoryStore {
    static let shared = CategoryStore()

    var categories: [String] = []

    private var currentUserID: UUID?

    func resetLocal() {
        currentUserID = nil
        categories = []
    }

    func loadRemote(userID: UUID) async {
        currentUserID = userID

        do {
            let rows: [CategoryRecord] = try await SupabaseService.client
                .from("workoutjournal_categories")
                .select("name")
                .eq("user_id", value: userID)
                .order("created_at", ascending: true)
                .execute()
                .value

            categories = rows.map(\.name)
        } catch {
            categories = []
        }
    }

    func add(_ rawName: String) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canAdd(name) else { return }
        guard let currentUserID else { return }

        categories.append(name)

        Task {
            try? await SupabaseService.client
                .from("workoutjournal_categories")
                .insert(CategoryRecord(userID: currentUserID, name: name))
                .execute()
        }
    }

    func remove(_ name: String) {
        categories.removeAll { $0 == name }
        guard let currentUserID else { return }

        Task {
            try? await SupabaseService.client
                .from("workoutjournal_categories")
                .delete()
                .eq("user_id", value: currentUserID)
                .eq("name", value: name)
                .execute()
        }
    }

    func canAdd(_ rawName: String) -> Bool {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 40 else { return false }
        return !categories.contains { $0.caseInsensitiveCompare(name) == .orderedSame }
    }
}

private struct CategoryRecord: Codable {
    let userID: UUID
    let name: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case name
    }
}
