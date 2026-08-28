import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager
    @Environment(CategoryStore.self) private var categoryStore
    @Environment(LanguagePreference.self) private var languagePreference
    @State private var newCategoryName = ""

    var body: some View {
        @Bindable var authManager = authManager
        @Bindable var languagePreference = languagePreference

        NavigationStack {
            List {
                Section {
                    if authManager.isSignedIn {
                        LabeledContent("Account", value: authManager.email ?? String(localized: "Signed In", locale: languagePreference.locale))
                        Button("Sign Out", role: .destructive) {
                            Task { await authManager.signOut() }
                        }
                        .disabled(authManager.isBusy)
                    } else {
                        Button("Sign in with Google") {
                            Task { await authManager.signInWithGoogle() }
                        }
                        .disabled(authManager.isBusy)
                    }
                } footer: {
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                    }
                }

                Section {
                    Picker("Language", selection: $languagePreference.selection) {
                        Text("Use System Language").tag(AppLanguage.system)
                        Text(verbatim: "한국어").tag(AppLanguage.korean)
                        Text(verbatim: "English").tag(AppLanguage.english)
                    }
                    .pickerStyle(.navigationLink)
                } footer: {
                    Text("The app uses your device language unless you choose a preferred language.")
                }

                if authManager.isSignedIn {
                    Section {
                        ForEach(categoryStore.categories, id: \.self) { name in
                            Text(name)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button("Delete", role: .destructive) {
                                        categoryStore.remove(name)
                                    }
                                }
                        }

                        HStack {
                            TextField("Category Name", text: $newCategoryName)
                                .onSubmit(addCategory)

                            Button("Add", action: addCategory)
                                .disabled(!categoryStore.canAdd(newCategoryName))
                        }
                    } header: {
                        Text("Categories")
                    } footer: {
                        Text("Add session types like PUSH, PULL, and LEGS.")
                    }
                }
            }
            .navigationTitle("Settings")
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
        .environment(LanguagePreference.shared)
}
