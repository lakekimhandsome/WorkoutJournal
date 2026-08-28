import Foundation
import Observation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case korean = "ko"
    case english = "en"

    var id: String { rawValue }

    var locale: Locale {
        switch self {
        case .system: .autoupdatingCurrent
        case .korean: Locale(identifier: "ko")
        case .english: Locale(identifier: "en")
        }
    }
}

@Observable
@MainActor
final class LanguagePreference {
    static let shared = LanguagePreference()
    static let storageKey = "preferredLanguage"

    var selection: AppLanguage {
        didSet {
            guard selection != oldValue else { return }
            if selection == .system {
                UserDefaults.standard.removeObject(forKey: Self.storageKey)
            } else {
                UserDefaults.standard.set(selection.rawValue, forKey: Self.storageKey)
            }
        }
    }

    var locale: Locale { selection.locale }

    private init() {
        if let rawValue = UserDefaults.standard.string(forKey: Self.storageKey),
           let language = AppLanguage(rawValue: rawValue),
           language != .system {
            selection = language
        } else {
            selection = .system
        }
    }
}
