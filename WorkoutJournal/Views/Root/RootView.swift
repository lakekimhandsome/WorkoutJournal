import SwiftUI

struct RootView: View {
    @Environment(TimerManager.self) private var timerManager
    @Environment(SessionStore.self) private var sessionStore
    @Environment(AuthManager.self) private var authManager
    @State private var path = NavigationPath()
    @State private var isSettingsPresented = false

    var body: some View {
        @Bindable var sessionStore = sessionStore
        @Bindable var authManager = authManager

        NavigationStack(path: $path) {
            Group {
                if authManager.isRestoring {
                    ProgressView()
                } else if !authManager.isSignedIn {
                    ContentUnavailableView {
                        Label("로그인", systemImage: "person.crop.circle")
                    } description: {
                        Text("Google 계정으로 로그인하면 운동 기록이 저장됩니다.")
                    } actions: {
                        Button("Google로 로그인") {
                            Task { await authManager.signInWithGoogle() }
                        }
                        .disabled(authManager.isBusy)
                    }
                } else {
                    List {
                        ForEach(sessionStore.sessions) { session in
                            NavigationLink(value: session.id) {
                                Text(session.date, format: .dateTime.year().month().day().weekday())
                            }
                            .swipeActions {
                                Button("삭제", role: .destructive) {
                                    sessionStore.remove(id: session.id)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("운동일지")
            .navigationSubtitle(authManager.isSignedIn ? "\(sessionStore.sessions.count)개의 세션" : "")
            .navigationDestination(for: WorkoutSession.ID.self) { id in
                if let index = sessionStore.sessions.firstIndex(where: { $0.id == id }) {
                    SessionDetailView(session: $sessionStore.sessions[index])
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: startNewSession) {
                        Image(systemName: "square.and.pencil")
                    }
                    .disabled(!authManager.isSignedIn)
                    .accessibilityLabel("새 세션")
                }

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
            .alert("로그인", isPresented: Binding(
                get: { authManager.errorMessage != nil },
                set: { if !$0 { authManager.errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) {
                    authManager.errorMessage = nil
                }
            } message: {
                Text(authManager.errorMessage ?? "")
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
            RestTimerView()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
        }
    }

    private func startNewSession() {
        let session = WorkoutSession.new()
        sessionStore.sessions.insert(session, at: 0)
        path.append(session.id)
    }
}
