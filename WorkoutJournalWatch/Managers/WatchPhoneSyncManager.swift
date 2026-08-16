import Foundation
import WatchConnectivity

@MainActor
final class WatchPhoneSyncManager: NSObject {
    static let shared = WatchPhoneSyncManager()

    private let totalCountKey = "totalSetIncrements"

    private var totalSetIncrements: Int {
        get { UserDefaults.standard.integer(forKey: totalCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: totalCountKey) }
    }

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func recordSetIncrement() {
        totalSetIncrements += 1
        pushCurrentTotal()
    }

    func syncIfNeeded() {
        pushCurrentTotal()
    }

    private func pushCurrentTotal() {
        let session = WCSession.default
        guard session.activationState == .activated else { return }

        let payload = [WatchSyncKey.totalSetIncrements: totalSetIncrements]
        try? session.updateApplicationContext(payload)

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        }
    }
}

extension WatchPhoneSyncManager: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.pushCurrentTotal()
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.pushCurrentTotal()
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard message[WatchSyncKey.request] as? String == WatchSyncKey.totalSetIncrements else { return }
        let total = UserDefaults.standard.integer(forKey: "totalSetIncrements")
        replyHandler([WatchSyncKey.totalSetIncrements: total])
    }
}

private enum WatchSyncKey {
    static let totalSetIncrements = "totalSetIncrements"
    static let request = "request"
}
