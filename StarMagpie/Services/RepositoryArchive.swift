import Foundation

struct StarRepositoryArchive: Codable, Equatable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let exportedAt: Date
    let repositories: [StarRepositoryRecord]

    init(
        schemaVersion: Int = Self.currentSchemaVersion,
        exportedAt: Date = Date(),
        repositories: [StarRepositoryRecord]
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.repositories = repositories
    }
}

struct StarRepositoryRecord: Codable, Equatable {
    let id: Int64
    let name: String
    let fullName: String
    let descriptionText: String?
    let htmlURL: String
    let stars: Int
    let forks: Int
    let language: String?
    let topics: [String]
    let ownerLogin: String
    let ownerAvatarURL: String
    let createdAt: Date
    let updatedAt: Date
    let pushedAt: Date?
    let starredAt: Date?
    let manualCategoryId: String?
    let notes: String
    let lastViewedAt: Date?

    init(repo: StarredRepo) {
        id = repo.id
        name = repo.name
        fullName = repo.fullName
        descriptionText = repo.descriptionText
        htmlURL = repo.htmlURL
        stars = repo.stars
        forks = repo.forks
        language = repo.language
        topics = repo.topics
        ownerLogin = repo.ownerLogin
        ownerAvatarURL = repo.ownerAvatarURL
        createdAt = repo.createdAt
        updatedAt = repo.updatedAt
        pushedAt = repo.pushedAt
        starredAt = repo.starredAt
        manualCategoryId = repo.manualCategoryId
        notes = repo.notes
        lastViewedAt = repo.lastViewedAt
    }
}

enum RepositoryArchiveError: LocalizedError {
    case emptyFile
    case unsupportedVersion(Int)

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return AppLocalizer.text("Repository archive is empty")
        case .unsupportedVersion(let version):
            return AppLocalizer.text("Unsupported repository archive version: %lld", version)
        }
    }
}

extension JSONEncoder {
    static var repositoryArchive: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

extension JSONDecoder {
    static var repositoryArchive: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
