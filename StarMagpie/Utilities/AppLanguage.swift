import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case simplifiedChinese

    var id: String { rawValue }

    var locale: Locale {
        switch self {
        case .system:
            return .autoupdatingCurrent
        case .english:
            return Locale(identifier: "en")
        case .simplifiedChinese:
            return Locale(identifier: "zh-Hans")
        }
    }

    var lprojName: String? {
        switch self {
        case .system:
            return nil
        case .english:
            return "en"
        case .simplifiedChinese:
            return "zh-Hans"
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    nonisolated static let languageDefaultsKey = "app.language"

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.languageDefaultsKey)
        }
    }

    init() {
        let rawValue = UserDefaults.standard.string(forKey: Self.languageDefaultsKey)
        language = rawValue.flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    var locale: Locale {
        language.locale
    }
}

enum AppLocalizer {
    static func text(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    static func text(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: locale, arguments: arguments)
    }

    private static var language: AppLanguage {
        let rawValue = UserDefaults.standard.string(forKey: AppSettings.languageDefaultsKey)
        return rawValue.flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    private static var locale: Locale {
        language.locale
    }

    private static var bundle: Bundle {
        guard let lprojName = language.lprojName,
              let path = Bundle.main.path(forResource: lprojName, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }
}
