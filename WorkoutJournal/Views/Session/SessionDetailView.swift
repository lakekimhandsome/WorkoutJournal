//
//  SessionDetailView.swift
//  WorkoutJournal
//

import SwiftUI

struct SessionDetailView: View {
    @Binding var session: WorkoutSession

    var body: some View {
        List {
            Section {
                header
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                notesSection
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        // .scrollEdgeEffectStyle(.soft, for: .top)
        .navigationTitle(session.title)
        .navigationBarTitleDisplayMode(.inline)
        // .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var header: some View {
        Text(session.date, format: .dateTime.year().month().day().weekday())
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("기록")
                .font(.headline)

            TextEditor(text: $session.notes)
                .font(.body)
                .frame(minHeight: 120)
                .scrollContentBackground(.hidden)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    @Previewable @State var session = MockData.sessions[0]

    NavigationStack {
        SessionDetailView(session: $session)
    }
}
