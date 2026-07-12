import SwiftUI

struct RootView: View {
    @State private var sessions = MockData.sessions
    @State private var isSettingsPresented = false
    @State private var isNewSessionPresented = false

    var body: some View {
        NavigationStack {
            List(sessions) { session in
                NavigationLink {
                    SessionDetailView(session: session)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.title)
                        Text(session.date, format: .sessionList)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .swipeActions {
                    Button("삭제", role: .destructive) {
                        sessions.removeAll { $0.id == session.id }
                    }
                }
            }
            .navigationTitle("운동일지")
            .navigationSubtitle("\(sessions.count)개의 세션")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("설정")
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    isNewSessionPresented = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 52, height: 52)
                        .background(.regularMaterial, in: Circle())
                        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("새 세션")
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView()
            }
            .sheet(isPresented: $isNewSessionPresented) {
                NewSessionView()
            }
        }
    }
}