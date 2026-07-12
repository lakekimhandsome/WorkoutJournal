//
//  NewSessionView.swift
//  WorkoutJournal
//

import SwiftUI

struct NewSessionView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
            }
            .navigationTitle("새 세션")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NewSessionView()
}
