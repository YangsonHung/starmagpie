import SwiftUI

struct LocalizedText: View {
    @EnvironmentObject private var appSettings: AppSettings
    let key: String

    var body: some View {
        Text(AppLocalizer.text(key, language: appSettings.language))
    }
}

struct LocalizedLabel: View {
    @EnvironmentObject private var appSettings: AppSettings
    let key: String
    let systemImage: String

    var body: some View {
        Label(AppLocalizer.text(key, language: appSettings.language), systemImage: systemImage)
    }
}

private struct LocalizedNavigationTitleModifier: ViewModifier {
    @EnvironmentObject private var appSettings: AppSettings
    let key: String

    func body(content: Content) -> some View {
        content.navigationTitle(AppLocalizer.text(key, language: appSettings.language))
    }
}

extension View {
    func localizedNavigationTitle(_ key: String) -> some View {
        modifier(LocalizedNavigationTitleModifier(key: key))
    }
}
