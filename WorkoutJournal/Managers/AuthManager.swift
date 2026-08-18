import Foundation
import GoogleSignIn
import Observation
import Auth
import Supabase
import UIKit

@Observable
@MainActor
final class AuthManager {
    static let shared = AuthManager()

    private(set) var user: User?
    private(set) var isRestoring = true
    private(set) var isBusy = false
    var errorMessage: String?

    var isSignedIn: Bool { user != nil }
    var email: String? { user?.email }

    private var didStart = false

    func start() {
        guard !didStart else { return }
        didStart = true

        Task {
            for await (_, session) in SupabaseService.client.auth.authStateChanges {
                let signedInUser = session?.user
                user = signedInUser
                isRestoring = false

                if let signedInUser {
                    await SessionStore.shared.loadRemote(userID: signedInUser.id)
                } else {
                    SessionStore.shared.resetLocal()
                }
            }
        }
    }

    func handleOpenURL(_ url: URL) {
        GIDSignIn.sharedInstance.handle(url)
    }

    func signInWithGoogle() async {
        errorMessage = nil
        guard let presentingViewController else {
            errorMessage = "로그인 화면을 열 수 없습니다."
            return
        }

        isBusy = true
        defer { isBusy = false }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: presentingViewController
            )
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Google 계정 정보를 가져오지 못했습니다."
                return
            }

            try await SupabaseService.client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .google,
                    idToken: idToken,
                    accessToken: result.user.accessToken.tokenString
                )
            )
        } catch let error as GIDSignInError where error.code == .canceled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        errorMessage = nil
        isBusy = true
        defer { isBusy = false }

        GIDSignIn.sharedInstance.signOut()
        do {
            try await SupabaseService.client.auth.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var presentingViewController: UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap(\.windows).first(where: \.isKeyWindow) ?? scenes.first?.windows.first
        guard var controller = window?.rootViewController else { return nil }
        while let presented = controller.presentedViewController {
            controller = presented
        }
        return controller
    }
}
