import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager
    @Environment(CategoryStore.self) private var categoryStore
    @State private var newCategoryName = ""

    var body: some View {
        @Bindable var authManager = authManager

        NavigationStack {
            List {
                Section {
                    if authManager.isSignedIn {
                        LabeledContent("계정", value: authManager.email ?? "로그인됨")
                        Button("로그아웃", role: .destructive) {
                            Task { await authManager.signOut() }
                        }
                        .disabled(authManager.isBusy)
                    } else {
                        Button("Google로 로그인") {
                            Task { await authManager.signInWithGoogle() }
                        }
                        .disabled(authManager.isBusy)
                    }
                } footer: {
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                    }
                }

                if authManager.isSignedIn {
                    Section {
                        ForEach(categoryStore.categories, id: \.self) { name in
                            Text(name)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button("삭제", role: .destructive) {
                                        categoryStore.remove(name)
                                    }
                                }
                        }

                        HStack {
                            TextField("카테고리 이름", text: $newCategoryName)
                                .onSubmit(addCategory)

                            Button("추가", action: addCategory)
                                .disabled(!categoryStore.canAdd(newCategoryName))
                        }
                    } header: {
                        Text("카테고리")
                    } footer: {
                        Text("PUSH, PULL, LEGS처럼 세션 종류를 추가합니다.")
                    }
                }
            }
            .navigationTitle("설정")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        dismiss()
                    }
                }
            }
            .overlay {
                if authManager.isBusy {
                    ProgressView()
                }
            }
        }
    }

    private func addCategory() {
        guard categoryStore.canAdd(newCategoryName) else { return }
        categoryStore.add(newCategoryName)
        newCategoryName = ""
    }
}

#Preview {
    SettingsView()
        .environment(AuthManager.shared)
        .environment(CategoryStore.shared)
}
