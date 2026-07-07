import Combine
import Foundation

@MainActor
final class RepositoryReadmeViewModel: ObservableObject {
    @Published private(set) var state: ReadmeLoadingState = .idle

    private let provider: any RepositoryReadmeProvider
    private var currentSnapshot: RepositorySnapshot?

    init(provider: any RepositoryReadmeProvider) {
        self.provider = provider
    }

    func load(repo: StarredRepo) async {
        let snapshot = RepositorySnapshot(id: repo.id, fullName: repo.fullName)
        currentSnapshot = snapshot
        await load(snapshot)
    }

    func retry() async {
        guard let currentSnapshot else { return }
        await load(currentSnapshot)
    }

    private func load(_ snapshot: RepositorySnapshot) async {
        do {
            let identity = try RepositoryIdentity(fullName: snapshot.fullName)
            state = .loading(repositoryId: snapshot.id)

            let readme = try await provider.readme(for: identity)
            guard isCurrent(snapshot) else { return }

            if readme.html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                state = .empty(repositoryId: snapshot.id)
            } else {
                state = .loaded(repositoryId: snapshot.id, readme: readme)
            }
        } catch RepositoryReadmeError.notFound {
            guard isCurrent(snapshot) else { return }
            state = .empty(repositoryId: snapshot.id)
        } catch {
            guard isCurrent(snapshot) else { return }
            state = .failed(repositoryId: snapshot.id, message: localizedMessage(for: error))
        }
    }

    private func isCurrent(_ snapshot: RepositorySnapshot) -> Bool {
        currentSnapshot == snapshot && !Task.isCancelled
    }

    private func localizedMessage(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }
        return error.localizedDescription
    }
}

private struct RepositorySnapshot: Equatable {
    let id: Int64
    let fullName: String
}
