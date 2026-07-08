import XCTest
@testable import StarMagpie

@MainActor
final class AppLanguageTests: XCTestCase {
    func testChangingLanguageUpdatesAppLocalizerImmediately() {
        let defaults = UserDefaults.standard
        let originalLanguage = defaults.string(forKey: AppSettings.languageDefaultsKey)
        defer {
            if let originalLanguage {
                defaults.set(originalLanguage, forKey: AppSettings.languageDefaultsKey)
            } else {
                defaults.removeObject(forKey: AppSettings.languageDefaultsKey)
            }
        }

        let settings = AppSettings()
        settings.language = .simplifiedChinese
        XCTAssertEqual(AppLocalizer.text("Stars"), "星标")

        settings.language = .english
        XCTAssertEqual(AppLocalizer.text("Stars"), "Stars")
        XCTAssertEqual(AppLocalizer.text("Owner"), "Owner")
        XCTAssertEqual(AppLocalizer.text("Web Apps"), "Web Apps")
    }

    func testChangingAppearancePersistsPreferredColorScheme() {
        let defaults = UserDefaults.standard
        let originalAppearance = defaults.string(forKey: AppSettings.appearanceDefaultsKey)
        defer {
            if let originalAppearance {
                defaults.set(originalAppearance, forKey: AppSettings.appearanceDefaultsKey)
            } else {
                defaults.removeObject(forKey: AppSettings.appearanceDefaultsKey)
            }
        }

        defaults.removeObject(forKey: AppSettings.appearanceDefaultsKey)
        let settings = AppSettings()

        XCTAssertEqual(settings.appearance, .system)
        XCTAssertNil(settings.appearance.colorScheme)

        settings.appearance = .dark
        XCTAssertEqual(defaults.string(forKey: AppSettings.appearanceDefaultsKey), AppAppearance.dark.rawValue)
        XCTAssertEqual(settings.appearance.colorScheme, .dark)

        settings.appearance = .light
        XCTAssertEqual(defaults.string(forKey: AppSettings.appearanceDefaultsKey), AppAppearance.light.rawValue)
        XCTAssertEqual(settings.appearance.colorScheme, .light)
    }
}
