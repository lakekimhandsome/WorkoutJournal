import SwiftUI

struct RootView: View {
    @Environment(TimerManager.self) private var timerManager
    @State private var sessions = MockData.sessions
    @State private var path = NavigationPath()
    @State private var isSettingsPresented = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(sessions) { session in
                    NavigationLink(value: session.id) {
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
            }
            .navigationTitle("운동일지")
            .navigationSubtitle("\(sessions.count)개의 세션")
            .navigationDestination(for: WorkoutSession.ID.self) { id in
                if let index = sessions.firstIndex(where: { $0.id == id }) {
                    SessionDetailView(session: $sessions[index])
                }
            }
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
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView()
            }
        }
        .overlay {
            if timerManager.isExpanded {
                Color.clear
                    .contentShape(.rect)
                    .onTapGesture {
                        withAnimation(.snappy) {
                            timerManager.isExpanded = false
                        }
                    }
                    .ignoresSafeArea()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar
        }
    }

    private var bottomBar: some View {
        HStack(alignment: .bottom) {
            newSessionButton
                .hidden()
                .accessibilityHidden(true)

            Spacer(minLength: 0)

            RestTimerView()

            Spacer(minLength: 0)

            newSessionButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private var newSessionButton: some View {
        Button(action: startNewSession) {
            Image(systemName: "square.and.pencil")
                .font(.title3.weight(.semibold))
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.large)
        .accessibilityLabel("새 세션")
    }

    private func startNewSession() {
        let session = WorkoutSession.new()
        sessions.insert(session, at: 0)
        path.append(session.id)
    }
}
