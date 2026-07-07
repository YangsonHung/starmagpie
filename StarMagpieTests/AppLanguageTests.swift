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
}
