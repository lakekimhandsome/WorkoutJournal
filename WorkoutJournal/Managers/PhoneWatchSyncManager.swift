import Foundation
import WatchConnectivity

@MainActor
final class PhoneWatchSyncManager: NSObject {
    static let shared = PhoneWatchSyncManager()

    private let appliedCountKey = "appliedWatchSetIncrements"

    private var appliedCount: Int {
        get { UserDefaults.standard.integer(forKey: appliedCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: appliedCountKey) }
    }

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func syncIfNeeded() {
        applyWatchTotal(from: WCSession.default.receivedApplicationContext)
        requestLatestTotalIfReachable()
    }

    private func requestLatestTotalIfReachable() {
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable else { return }

        session.sendMessage(
            [WatchSyncKey.request: WatchSyncKey.totalSetIncrements],
            replyHandler: { reply in
                Task { @MainActor in
                    self.applyWatchTotal(from: reply)
                }
            },
            errorHandler: { _ in }
        )
    }

    private func applyWatchTotal(from payload: [String: Any]) {
        guard let total = payload[WatchSyncKey.totalSetIncrements] as? Int else { return }
        let delta = total - appliedCount
        guard delta > 0, SessionStore.shared.hasLatestExercise else { return }

        SessionStore.shared.addSetsToLatestExercise(count: delta)
        appliedCount = total
    }
}

extension PhoneWatchSyncManager: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.syncIfNeeded()
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.syncIfNeeded()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.applyWatchTotal(from: applicationContext)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.applyWatchTotal(from: message)
        }
    }
}

private enum WatchSyncKey {
    static let totalSetIncrements = "totalSetIncrements"
    static let request = "request"
}
