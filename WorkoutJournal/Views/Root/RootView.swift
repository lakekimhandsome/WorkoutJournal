import SwiftUI

struct RootView: View {
    @Environment(TimerManager.self) private var timerManager
    @Environment(SessionStore.self) private var sessionStore
    @Environment(CategoryStore.self) private var categoryStore
    @Environment(AuthManager.self) private var authManager
    @Environment(\.locale) private var locale
    @State private var path = NavigationPath()
    @State private var isSettingsPresented = false
    @State private var isKeyboardPresented = false

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
                    .onScrollPhaseChange { _, newPhase in
                        if newPhase.isScrolling {
                            collapseTimer()
                        }
                    }
                    .simultaneousGesture(collapseTimerOnScrollGesture)
                }
            }
            .navigationTitle("Workouts")
            .navigationSubtitle(sessionCountSubtitle)
            .navigationDestination(for: WorkoutSession.ID.self) { id in
                if let index = sessionStore.sessions.firstIndex(where: { $0.id == id }) {
                    SessionDetailView(
                        session: $sessionStore.sessions[index],
                        isKeyboardPresented: $isKeyboardPresented
                    )
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
                SettingsView(isKeyboardPresented: $isKeyboardPresented)
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
        .onChange(of: path.count) {
            collapseTimer()
        }
        .onChange(of: isSettingsPresented) { _, isPresented in
            if isPresented {
                collapseTimer()
            }
        }
        .onChange(of: isKeyboardPresented) { _, isPresented in
            if isPresented {
                timerManager.isExpanded = false
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !isKeyboardPresented {
                RestTimerView()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: isKeyboardPresented)
    }

    private func collapseTimer() {
        guard timerManager.isExpanded else { return }
        withAnimation(.snappy) {
            timerManager.isExpanded = false
        }
    }

    private var collapseTimerOnScrollGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard abs(value.translation.height) > abs(value.translation.width) else { return }
                collapseTimer()
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
