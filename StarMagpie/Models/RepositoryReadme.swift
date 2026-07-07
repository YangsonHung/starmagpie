import Foundation

struct RepositoryIdentity: Equatable, Hashable {
    let owner: String
    let name: String

    var fullName: String {
        "\(owner)/\(name)"
    }

    init(fullName: String) throws {
        let parts = fullName.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2,
              !parts[0].isEmpty,
              !parts[1].isEmpty else {
            throw RepositoryReadmeError.invalidRepositoryName
        }

        owner = String(parts[0])
        name = String(parts[1])
    }
}

struct RepositoryReadme: Equatable {
    let html: String
    let baseURL: URL
}

enum RepositoryReadmeError: LocalizedError, Equatable {
    case invalidRepositoryName
    case missingToken
    case notFound
    case invalidEncoding

    var errorDescription: String? {
        switch self {
        case .invalidRepositoryName:
            return AppLocalizer.text("Repository README is unavailable because the repository name is invalid.")
        case .missingToken:
            return AppLocalizer.text("GitHub token not found. Please sign in again.")
        case .notFound:
            return AppLocalizer.text("No README found")
        case .invalidEncoding:
            return AppLocalizer.text("GitHub API returned an invalid response")
        }
    }
}

enum ReadmeLoadingState: Equatable {
    case idle
    case loading(repositoryId: Int64)
    case loaded(repositoryId: Int64, readme: RepositoryReadme)
    case empty(repositoryId: Int64)
    case failed(repositoryId: Int64, message: String)
}
