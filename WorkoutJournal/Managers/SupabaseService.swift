import Foundation
import Supabase

enum SupabaseService {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://pbmzjxjtctwhgxxbcgxl.supabase.co")!,
        supabaseKey: "sb_publishable_unUQNuQ1GsBBT6W45Gmgfg_I12SXTF9"
    )
}
