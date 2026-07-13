//
//  SessionSidebarView.swift
//  WorkoutJournal
//

import SwiftUI

struct SessionSidebarView: View {
    let sessions: [WorkoutSession]
    @Binding var selection: WorkoutSession.ID?
    var onSessionSelected: () -> Void = {}

    var body: some View {
        NavigationStack {
            List(sessions) { session in
                Button {
                    selection = session.id
                    onSessionSelected()
                } label: {
                    SessionRowView(session: session)
                }
                .buttonStyle(.plain)
                .listRowBackground(
                    session.id == selection
                        ? Color.primary.opacity(0.08)
                        : Color.clear
                )
            }
            .listStyle(.plain)
            // .scrollEdgeEffectStyle(.soft, for: .top)
            .navigationTitle("세션")
            .navigationBarTitleDisplayMode(.inline)
            // .toolbarBackground(.hidden, for: .navigationBar)
        }
        .background(.background)
    }
}

private struct SessionRowView: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.title)
                .font(.body)
                .foregroundStyle(.primary)

            Text(session.date, format: .sessionList)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    SessionSidebarView(
        sessions: MockData.sessions,
        selection: .constant(MockData.sessions.first?.id)
    )
    .frame(width: 300)
}
