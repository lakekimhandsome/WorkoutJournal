import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager

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
}

#Preview {
    SettingsView()
        .environment(AuthManager.shared)
}
