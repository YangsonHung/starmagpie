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

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    nonisolated static let languageDefaultsKey = "app.language"
    nonisolated static let appearanceDefaultsKey = "app.appearance"

    @Published var language: AppLanguage {
        willSet {
            UserDefaults.standard.set(newValue.rawValue, forKey: Self.languageDefaultsKey)
        }
    }

    @Published var appearance: AppAppearance {
        willSet {
            UserDefaults.standard.set(newValue.rawValue, forKey: Self.appearanceDefaultsKey)
        }
    }

    init() {
        let languageRawValue = UserDefaults.standard.string(forKey: Self.languageDefaultsKey)
        language = languageRawValue.flatMap(AppLanguage.init(rawValue:)) ?? .system

        let appearanceRawValue = UserDefaults.standard.string(forKey: Self.appearanceDefaultsKey)
        appearance = appearanceRawValue.flatMap(AppAppearance.init(rawValue:)) ?? .system
    }
}

enum AppLocalizer {
    static func text(_ key: String) -> String {
        text(key, language: language)
    }

    static func text(_ key: String, language: AppLanguage) -> String {
        bundle(for: language).localizedString(forKey: key, value: nil, table: nil)
    }

    static func text(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: locale, arguments: arguments)
    }

    static func text(_ key: String, language: AppLanguage, _ arguments: CVarArg...) -> String {
        String(format: text(key, language: language), locale: language.locale, arguments: arguments)
    }

    private static var language: AppLanguage {
        let rawValue = UserDefaults.standard.string(forKey: AppSettings.languageDefaultsKey)
        return rawValue.flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    private static var locale: Locale {
        language.locale
    }

    private static var bundle: Bundle {
        bundle(for: language)
    }

    private static func bundle(for language: AppLanguage) -> Bundle {
        guard let lprojName = language.lprojName,
              let path = Bundle.main.path(forResource: lprojName, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }
}

enum AppDateFormatter {
    static func text(
        _ date: Date,
        date dateStyle: Date.FormatStyle.DateStyle,
        time timeStyle: Date.FormatStyle.TimeStyle,
        language: AppLanguage
    ) -> String {
        date.formatted(Date.FormatStyle(date: dateStyle, time: timeStyle).locale(language.locale))
    }
}
