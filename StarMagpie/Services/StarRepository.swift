import Foundation
import SwiftData

@MainActor
final class StarRepository: ObservableObject {
    @Published var isSyncing = false
    @Published var errorMessage: String?
    @Published var statusMessage: String?
    @Published var currentUser: GitHubUser?
    @Published var lastSyncDate: Date?

    private let modelContext: ModelContext
    private let tokenStore: KeychainTokenStore
    private let clientFactory: (String) -> GitHubClient

    init(
        modelContext: ModelContext,
        tokenStore: KeychainTokenStore = KeychainTokenStore(),
        clientFactory: @escaping (String) -> GitHubClient = { GitHubClient(token: $0) }
    ) {
        self.modelContext = modelContext
        self.tokenStore = tokenStore
        self.clientFactory = clientFactory
    }

    var hasSavedToken: Bool {
        do {
            return try tokenStore.loadToken() != nil
        } catch {
            return false
        }
    }

    func signIn(token: String) async -> Bool {
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedToken.isEmpty else {
            errorMessage = AppLocalizer.text("Enter a GitHub Personal Access Token")
            return false
        }

        do {
            let user = try await clientFactory(trimmedToken).validateToken()
            try tokenStore.saveToken(trimmedToken)
            currentUser = user
            errorMessage = nil
            return true
        } catch {
            errorMessage = localizedMessage(for: error)
            return false
        }
    }

    func updateToken(_ token: String) async -> Bool {
        let success = await signIn(token: token)
        if success {
            statusMessage = AppLocalizer.text("GitHub token updated")
        }
        return success
    }

    func syncStars() async {
        guard let token = try? tokenStore.loadToken() else {
            errorMessage = AppLocalizer.text("GitHub token not found. Please sign in again.")
            return
        }

        isSyncing = true
        errorMessage = nil
        defer { isSyncing = false }

        do {
            let items = try await clientFactory(token).fetchAllStarredRepositories()
            try Self.merge(remoteItems: items, into: modelContext)
            lastSyncDate = Date()
            statusMessage = AppLocalizer.text("Synced %lld repositories", items.count)
        } catch {
            errorMessage = localizedMessage(for: error)
        }
    }

    func unstar(_ repo: StarredRepo) async {
        guard let token = try? tokenStore.loadToken() else {
            errorMessage = AppLocalizer.text("GitHub token not found. Please sign in again.")
            return
        }

        let parts = repo.fullName.split(separator: "/", maxSplits: 1).map(String.init)
        guard parts.count == 2 else {
            errorMessage = AppLocalizer.text("Invalid repository full name: %@", repo.fullName)
            return
        }

        do {
            try await clientFactory(token).unstar(owner: parts[0], repo: parts[1])
            modelContext.delete(repo)
            try modelContext.save()
            errorMessage = nil
            statusMessage = AppLocalizer.text("Unstarred %@", repo.fullName)
        } catch {
            errorMessage = localizedMessage(for: error)
        }
    }

    func exportArchiveData() throws -> Data {
        let data = try Self.exportArchiveData(from: modelContext)
        errorMessage = nil
        statusMessage = AppLocalizer.text("Repository archive is ready")
        return data
    }

    @discardableResult
    func importArchiveData(_ data: Data) throws -> Int {
        let count = try Self.importArchiveData(data, into: modelContext)
        errorMessage = nil
        statusMessage = AppLocalizer.text("Imported %lld repositories", count)
        return count
    }

    func report(_ error: Error) {
        statusMessage = nil
        errorMessage = localizedMessage(for: error)
    }

    func signOut(clearLocalData: Bool = true) {
        do {
            try tokenStore.deleteToken()
            currentUser = nil
            if clearLocalData {
                let descriptor = FetchDescriptor<StarredRepo>()
                let repositories = try modelContext.fetch(descriptor)
                repositories.forEach { modelContext.delete($0) }
                try modelContext.save()
            }
            errorMessage = nil
        } catch {
            errorMessage = localizedMessage(for: error)
        }
    }

    static func merge(remoteItems: [GitHubStarredItem], into modelContext: ModelContext) throws {
        let existingRepositories = try modelContext.fetch(FetchDescriptor<StarredRepo>())
        let existingById = Dictionary(uniqueKeysWithValues: existingRepositories.map { ($0.id, $0) })
        let remoteIds = Set(remoteItems.map { $0.repo.id })

        for item in remoteItems {
            if let existing = existingById[item.repo.id] {
                existing.updateRemoteFields(from: item)
            } else {
                modelContext.insert(StarredRepo(item: item))
            }
        }

        for localRepo in existingRepositories where !remoteIds.contains(localRepo.id) {
            modelContext.delete(localRepo)
        }

        try modelContext.save()
    }

    static func exportArchiveData(from modelContext: ModelContext) throws -> Data {
        let descriptor = FetchDescriptor<StarredRepo>(
            sortBy: [SortDescriptor(\.fullName, order: .forward)]
        )
        let repositories = try modelContext.fetch(descriptor)
        let archive = StarRepositoryArchive(
            repositories: repositories.map(StarRepositoryRecord.init(repo:))
        )
        return try JSONEncoder.repositoryArchive.encode(archive)
    }

    @discardableResult
    static func importArchiveData(_ data: Data, into modelContext: ModelContext) throws -> Int {
        guard !data.isEmpty else {
            throw RepositoryArchiveError.emptyFile
        }

        let archive = try JSONDecoder.repositoryArchive.decode(StarRepositoryArchive.self, from: data)
        guard archive.schemaVersion == StarRepositoryArchive.currentSchemaVersion else {
            throw RepositoryArchiveError.unsupportedVersion(archive.schemaVersion)
        }

        let existingRepositories = try modelContext.fetch(FetchDescriptor<StarredRepo>())
        var repositoriesById = Dictionary(uniqueKeysWithValues: existingRepositories.map { ($0.id, $0) })

        for record in archive.repositories {
            if let existing = repositoriesById[record.id] {
                existing.updateImportedFields(from: record)
            } else {
                let inserted = StarredRepo(record: record)
                modelContext.insert(inserted)
                repositoriesById[record.id] = inserted
            }
        }

        try modelContext.save()
        return archive.repositories.count
    }

    private func localizedMessage(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }
        return error.localizedDescription
    }
}
