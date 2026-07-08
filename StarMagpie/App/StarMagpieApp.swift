import SwiftData
import SwiftUI

@main
struct StarMagpieApp: App {
    @StateObject private var appSettings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
                .preferredColorScheme(appSettings.appearance.colorScheme)
        }
        .modelContainer(for: StarredRepo.self)
    }
}
