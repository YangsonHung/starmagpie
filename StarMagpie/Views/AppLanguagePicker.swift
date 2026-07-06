import SwiftUI

struct AppLanguagePicker: View {
    @EnvironmentObject private var appSettings: AppSettings

    var body: some View {
        Picker("App Language", selection: $appSettings.language) {
            Text("Follow System").tag(AppLanguage.system)
            Text("English").tag(AppLanguage.english)
            Text("Simplified Chinese").tag(AppLanguage.simplifiedChinese)
        }
        .pickerStyle(.menu)
        .frame(width: 170)
    }
}

