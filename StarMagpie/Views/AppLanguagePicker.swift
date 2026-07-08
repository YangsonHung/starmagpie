import SwiftUI

struct AppLanguagePicker: View {
    @EnvironmentObject private var appSettings: AppSettings

    var body: some View {
        Picker(localized("App Language"), selection: $appSettings.language) {
            Text(localized("Follow System")).tag(AppLanguage.system)
            Text(localized("English")).tag(AppLanguage.english)
            Text(localized("Simplified Chinese")).tag(AppLanguage.simplifiedChinese)
        }
        .pickerStyle(.menu)
        .frame(width: 170)
    }

    private func localized(_ key: String) -> String {
        AppLocalizer.text(key, language: appSettings.language)
    }
}

struct AppAppearancePicker: View {
    @EnvironmentObject private var appSettings: AppSettings

    var body: some View {
        Picker(localized("App Appearance"), selection: $appSettings.appearance) {
            Text(localized("Follow System")).tag(AppAppearance.system)
            Text(localized("Light")).tag(AppAppearance.light)
            Text(localized("Dark")).tag(AppAppearance.dark)
        }
        .pickerStyle(.menu)
        .frame(width: 145)
        .help(localized("App Appearance"))
    }

    private func localized(_ key: String) -> String {
        AppLocalizer.text(key, language: appSettings.language)
    }
}
