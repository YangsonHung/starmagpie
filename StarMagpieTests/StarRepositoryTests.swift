import SwiftData
import XCTest
@testable import StarMagpie

@MainActor
final class StarRepositoryTests: XCTestCase {
    func testMergePreservesLocalFieldsAndUpdatesRemoteFields() throws {
        let context = try makeContext()
        let local = StarredRepo(item: TestFixtures.starred(id: 1, name: "Old", description: "old", stars: 1))
        local.manualCategoryId = "devtools"
        local.notes = "keep notes"
        local.lastViewedAt = TestFixtures.date
        context.insert(local)
        try context.save()

        let remote = TestFixtures.starred(
            id: 1,
            name: "New",
            fullName: "octocat/New",
            description: "new",
            stars: 99,
            topics: ["swiftui"]
        )

        try StarRepository.merge(remoteItems: [remote], into: context)

        let repos = try context.fetch(FetchDescriptor<StarredRepo>())
        XCTAssertEqual(repos.count, 1)
        XCTAssertEqual(repos[0].name, "New")
        XCTAssertEqual(repos[0].stars, 99)
        XCTAssertEqual(repos[0].topics, ["swiftui"])
        XCTAssertEqual(repos[0].manualCategoryId, "devtools")
        XCTAssertEqual(repos[0].notes, "keep notes")
        XCTAssertEqual(repos[0].lastViewedAt, TestFixtures.date)
    }

    func testMergeDeletesReposMissingFromRemoteStars() throws {
        let context = try makeContext()
        context.insert(StarredRepo(item: TestFixtures.starred(id: 1, name: "Keep")))
        context.insert(StarredRepo(item: TestFixtures.starred(id: 2, name: "Remove")))
        try context.save()

        try StarRepository.merge(remoteItems: [TestFixtures.starred(id: 1, name: "Keep")], into: context)

        let repos = try context.fetch(FetchDescriptor<StarredRepo>())
        XCTAssertEqual(repos.map(\.id), [1])
    }

    func testArchiveExportAndImportRestoresLocalFields() throws {
        let sourceContext = try makeContext()
        let source = StarredRepo(item: TestFixtures.starred(id: 1, name: "Archive", topics: ["swift", "macos"]))
        source.manualCategoryId = "devtools"
        source.notes = "restore me"
        source.lastViewedAt = TestFixtures.date.addingTimeInterval(300)
        sourceContext.insert(source)
        try sourceContext.save()

        let data = try StarRepository.exportArchiveData(from: sourceContext)

        let targetContext = try makeContext()
        let importedCount = try StarRepository.importArchiveData(data, into: targetContext)
        let repos = try targetContext.fetch(FetchDescriptor<StarredRepo>())

        XCTAssertEqual(importedCount, 1)
        XCTAssertEqual(repos.count, 1)
        XCTAssertEqual(repos[0].fullName, "octocat/Archive")
        XCTAssertEqual(repos[0].topics, ["swift", "macos"])
        XCTAssertEqual(repos[0].manualCategoryId, "devtools")
        XCTAssertEqual(repos[0].notes, "restore me")
        XCTAssertEqual(repos[0].lastViewedAt, TestFixtures.date.addingTimeInterval(300))
    }

    func testArchiveImportMergesWithoutDeletingLocalRepos() throws {
        let sourceContext = try makeContext()
        let replacement = StarredRepo(item: TestFixtures.starred(id: 1, name: "Replacement", stars: 20))
        replacement.notes = "imported notes"
        sourceContext.insert(replacement)
        try sourceContext.save()
        let data = try StarRepository.exportArchiveData(from: sourceContext)

        let targetContext = try makeContext()
        let existing = StarredRepo(item: TestFixtures.starred(id: 1, name: "Old", stars: 1))
        let untouched = StarredRepo(item: TestFixtures.starred(id: 2, name: "Untouched", stars: 3))
        targetContext.insert(existing)
        targetContext.insert(untouched)
        try targetContext.save()

        try StarRepository.importArchiveData(data, into: targetContext)

        let repos = try targetContext.fetch(FetchDescriptor<StarredRepo>(
            sortBy: [SortDescriptor(\.id, order: .forward)]
        ))
        XCTAssertEqual(repos.map(\.id), [1, 2])
        XCTAssertEqual(repos[0].name, "Replacement")
        XCTAssertEqual(repos[0].stars, 20)
        XCTAssertEqual(repos[0].notes, "imported notes")
        XCTAssertEqual(repos[1].name, "Untouched")
    }

    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: StarredRepo.self, configurations: configuration)
        return ModelContext(container)
    }
}
