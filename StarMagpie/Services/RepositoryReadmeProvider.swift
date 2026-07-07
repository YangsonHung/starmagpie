import Foundation

protocol RepositoryReadmeProvider {
    func readme(for identity: RepositoryIdentity) async throws -> RepositoryReadme
}

final class GitHubRepositoryReadmeProvider: RepositoryReadmeProvider {
    private let tokenStore: KeychainTokenStore
    private let clientFactory: (String) -> GitHubClient

    init(
        tokenStore: KeychainTokenStore = KeychainTokenStore(),
        clientFactory: @escaping (String) -> GitHubClient = { GitHubClient(token: $0) }
    ) {
        self.tokenStore = tokenStore
        self.clientFactory = clientFactory
    }

    func readme(for identity: RepositoryIdentity) async throws -> RepositoryReadme {
        guard let token = try tokenStore.loadToken() else {
            throw RepositoryReadmeError.missingToken
        }

        return try await clientFactory(token).fetchReadmeHTML(owner: identity.owner, repo: identity.name)
    }
}
