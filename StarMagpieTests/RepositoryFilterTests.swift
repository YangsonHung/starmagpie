import XCTest
@testable import StarMagpie

final class RepositoryFilterTests: XCTestCase {
    func testSearchMatchesNameDescriptionTopicsAndNotes() {
        let repo = StarredRepo(item: TestFixtures.starred(
            id: 1,
            name: "Stars",
            description: "Native mac app",
            topics: ["swiftui"],
            starredAt: TestFixtures.date
        ))
        repo.notes = "favorite productivity tool"

        let results = RepositoryFilter.filtered(
            [repo],
            searchText: "productivity swiftui",
            selectedCategoryId: RepositoryFilter.allCategoryId,
            selectedLanguage: nil,
            sortOption: .starsDesc
        )

        XCTAssertEqual(results.map(\.id), [1])
    }

    func testLanguageFilterAndCategoryMatching() {
        let swiftRepo = StarredRepo(item: TestFixtures.starred(
            id: 1,
            name: "Native",
            description: "desktop gui",
            language: "Swift"
        ))
        let jsRepo = StarredRepo(item: TestFixtures.starred(
            id: 2,
            name: "Frontend",
            description: "react frontend",
            language: "TypeScript"
        ))

        let results = RepositoryFilter.filtered(
            [swiftRepo, jsRepo],
            searchText: "",
            selectedCategoryId: "desktop",
            selectedLanguage: "Swift",
            sortOption: .starsDesc
        )

        XCTAssertEqual(results.map(\.id), [1])
    }

    func testManualCategoryOverridesKeywordCategory() {
        let repo = StarredRepo(item: TestFixtures.starred(
            id: 1,
            name: "Frontend",
            description: "react frontend",
            language: "TypeScript"
        ))
        repo.manualCategoryId = "productivity"

        XCTAssertTrue(CategoryResolver.matches(repo: repo, selectedCategoryId: "productivity"))
        XCTAssertFalse(CategoryResolver.matches(repo: repo, selectedCategoryId: "web"))
    }

    func testSortByStarsDescending() {
        let low = StarredRepo(item: TestFixtures.starred(id: 1, name: "Low", stars: 1))
        let high = StarredRepo(item: TestFixtures.starred(id: 2, name: "High", stars: 100))

        let results = RepositoryFilter.filtered(
            [low, high],
            searchText: "",
            selectedCategoryId: RepositoryFilter.allCategoryId,
            selectedLanguage: nil,
            sortOption: .starsDesc
        )

        XCTAssertEqual(results.map(\.id), [2, 1])
    }
}

