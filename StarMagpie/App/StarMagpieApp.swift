import SwiftData
import SwiftUI

@main
struct StarMagpieApp: App {
    @StateObject private var appSettings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
                .environment(\.locale, appSettings.locale)
        }
        .modelContainer(for: StarredRepo.self)
    }
}
