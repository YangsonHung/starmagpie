import XCTest
@testable import StarMagpie

@MainActor
final class RepositoryReadmeViewModelTests: XCTestCase {
    func testLoadSuccessPublishesLoadedState() async throws {
        let readme = RepositoryReadme(html: "<h1>Hello</h1>", baseURL: URL(string: "https://github.com/octocat/Repo")!)
        let provider = MockReadmeProvider(responses: [.success(readme)])
        let viewModel = RepositoryReadmeViewModel(provider: provider)
        let repo = StarredRepo(item: TestFixtures.starred(id: 1, name: "Repo"))

        await viewModel.load(repo: repo)

        XCTAssertEqual(viewModel.state, .loaded(repositoryId: 1, readme: readme))
        XCTAssertEqual(provider.identities, [try RepositoryIdentity(fullName: "octocat/Repo")])
    }

    func testLoadNotFoundPublishesEmptyState() async {
        let provider = MockReadmeProvider(responses: [.failure(RepositoryReadmeError.notFound)])
        let viewModel = RepositoryReadmeViewModel(provider: provider)
        let repo = StarredRepo(item: TestFixtures.starred(id: 1, name: "Repo"))

        await viewModel.load(repo: repo)

        XCTAssertEqual(viewModel.state, .empty(repositoryId: 1))
    }

    func testLoadFailurePublishesFailedState() async {
        let provider = MockReadmeProvider(responses: [.failure(LocalizedFailure(message: "boom"))])
        let viewModel = RepositoryReadmeViewModel(provider: provider)
        let repo = StarredRepo(item: TestFixtures.starred(id: 1, name: "Repo"))

        await viewModel.load(repo: repo)

        XCTAssertEqual(viewModel.state, .failed(repositoryId: 1, message: "boom"))
    }

    func testRetryReloadsCurrentRepository() async throws {
        let readme = RepositoryReadme(html: "<p>Retry</p>", baseURL: URL(string: "https://github.com/octocat/Repo")!)
        let provider = MockReadmeProvider(responses: [
            .failure(LocalizedFailure(message: "temporary failure")),
            .success(readme)
        ])
        let viewModel = RepositoryReadmeViewModel(provider: provider)
        let repo = StarredRepo(item: TestFixtures.starred(id: 1, name: "Repo"))

        await viewModel.load(repo: repo)
        await viewModel.retry()

        XCTAssertEqual(viewModel.state, .loaded(repositoryId: 1, readme: readme))
        XCTAssertEqual(provider.identities.count, 2)
        XCTAssertEqual(provider.identities, [
            try RepositoryIdentity(fullName: "octocat/Repo"),
            try RepositoryIdentity(fullName: "octocat/Repo")
        ])
    }

    func testStaleLoadDoesNotReplaceCurrentRepositoryState() async throws {
        let provider = DelayedReadmeProvider()
        let viewModel = RepositoryReadmeViewModel(provider: provider)
        let slowRepo = StarredRepo(item: TestFixtures.starred(id: 1, name: "Slow"))
        let fastRepo = StarredRepo(item: TestFixtures.starred(id: 2, name: "Fast"))
        let fastReadme = RepositoryReadme(
            html: "<p>Fast</p>",
            baseURL: URL(string: "https://github.com/octocat/Fast")!
        )

        let slowTask = Task { await viewModel.load(repo: slowRepo) }
        try await Task.sleep(nanoseconds: 20_000_000)
        await viewModel.load(repo: fastRepo)
        await slowTask.value

        XCTAssertEqual(viewModel.state, .loaded(repositoryId: 2, readme: fastReadme))
    }
}

private final class MockReadmeProvider: RepositoryReadmeProvider {
    enum Response {
        case success(RepositoryReadme)
        case failure(Error)
    }

    private(set) var identities: [RepositoryIdentity] = []
    private var responses: [Response]

    init(responses: [Response]) {
        self.responses = responses
    }

    func readme(for identity: RepositoryIdentity) async throws -> RepositoryReadme {
        identities.append(identity)
        let response = responses.removeFirst()
        switch response {
        case .success(let readme):
            return readme
        case .failure(let error):
            throw error
        }
    }
}

private final class DelayedReadmeProvider: RepositoryReadmeProvider {
    func readme(for identity: RepositoryIdentity) async throws -> RepositoryReadme {
        if identity.name == "Slow" {
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        return RepositoryReadme(
            html: "<p>\(identity.name)</p>",
            baseURL: URL(string: "https://github.com/\(identity.fullName)")!
        )
    }
}

private struct LocalizedFailure: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}
