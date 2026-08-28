import SwiftUI

struct RootView: View {
    @Environment(TimerManager.self) private var timerManager
    @Environment(SessionStore.self) private var sessionStore
    @Environment(CategoryStore.self) private var categoryStore
    @Environment(AuthManager.self) private var authManager
    @Environment(\.locale) private var locale
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
                        Label("Sign In", systemImage: "person.crop.circle")
                    } description: {
                        Text("Sign in with your Google account to save your workouts.")
                    } actions: {
                        Button("Sign in with Google") {
                            Task { await authManager.signInWithGoogle() }
                        }
                        .disabled(authManager.isBusy)
                    }
                } else {
                    List {
                        ForEach(SessionDateSection.groups(from: sessionStore.sessions)) { group in
                            Section(group.section.title(locale: locale)) {
                                ForEach(group.sessions) { session in
                                    NavigationLink(value: session.id) {
                                        LabeledContent {
                                            if !session.category.isEmpty {
                                                Text(session.category)
                                            }
                                        } label: {
                                            Text(session.date, format: .dateTime.year().month().day().weekday())
                                        }
                                    }
                                    .swipeActions {
                                        Button("Delete", role: .destructive) {
                                            sessionStore.remove(id: session.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Workout Journal")
            .navigationSubtitle(sessionCountSubtitle)
            .navigationDestination(for: WorkoutSession.ID.self) { id in
                if let index = sessionStore.sessions.firstIndex(where: { $0.id == id }) {
                    SessionDetailView(session: $sessionStore.sessions[index])
                }
            }
            .toolbar {
                if authManager.isSignedIn {
                    ToolbarItem(placement: .largeSubtitle) {
                        Text("\(sessionStore.sessions.count) Sessions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if categoryStore.categories.isEmpty {
                            Button("Add Category") {
                                isSettingsPresented = true
                            }
                        } else {
                            ForEach(categoryStore.categories, id: \.self) { category in
                                Button(category) {
                                    startNewSession(category: category)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .disabled(!authManager.isSignedIn)
                    .menuIndicator(.hidden)
                    .menuOrder(.fixed)
                    .accessibilityLabel("New Session")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView()
            }
            .alert("Sign In", isPresented: Binding(
                get: { authManager.errorMessage != nil },
                set: { if !$0 { authManager.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {
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

    private func startNewSession(category: String) {
        let session = WorkoutSession.new(category: category)
        sessionStore.sessions.insert(session, at: 0)
        path.append(session.id)
    }

    private var sessionCountSubtitle: Text {
        if authManager.isSignedIn {
            Text("\(sessionStore.sessions.count) Sessions")
        } else {
            Text("")
        }
    }
}
