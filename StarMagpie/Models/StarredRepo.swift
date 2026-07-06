import Foundation
import SwiftData

@Model
final class StarredRepo: Identifiable {
    @Attribute(.unique) var id: Int64
    var name: String
    var fullName: String
    var descriptionText: String?
    var htmlURL: String
    var stars: Int
    var forks: Int
    var language: String?
    var topicsJSON: String
    var ownerLogin: String
    var ownerAvatarURL: String
    var createdAt: Date
    var updatedAt: Date
    var pushedAt: Date?
    var starredAt: Date?
    var manualCategoryId: String?
    var notes: String
    var lastViewedAt: Date?

    init(item: GitHubStarredItem) {
        let repo = item.repo
        id = repo.id
        name = repo.name
        fullName = repo.fullName
        descriptionText = repo.description
        htmlURL = repo.htmlURL
        stars = repo.stargazersCount
        forks = repo.forks
        language = repo.language
        topicsJSON = Self.encodeTopics(repo.topics)
        ownerLogin = repo.owner.login
        ownerAvatarURL = repo.owner.avatarURL
        createdAt = repo.createdAt
        updatedAt = repo.updatedAt
        pushedAt = repo.pushedAt
        starredAt = item.starredAt
        manualCategoryId = nil
        notes = ""
        lastViewedAt = nil
    }

    init(record: StarRepositoryRecord) {
        id = record.id
        name = record.name
        fullName = record.fullName
        descriptionText = record.descriptionText
        htmlURL = record.htmlURL
        stars = record.stars
        forks = record.forks
        language = record.language
        topicsJSON = Self.encodeTopics(record.topics)
        ownerLogin = record.ownerLogin
        ownerAvatarURL = record.ownerAvatarURL
        createdAt = record.createdAt
        updatedAt = record.updatedAt
        pushedAt = record.pushedAt
        starredAt = record.starredAt
        manualCategoryId = record.manualCategoryId
        notes = record.notes
        lastViewedAt = record.lastViewedAt
    }

    var topics: [String] {
        guard let data = topicsJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return decoded
    }

    var languageDisplay: String {
        language?.isEmpty == false ? language! : AppLocalizer.text("Unknown")
    }

    var categoryDisplayName: String {
        let categoryId = CategoryResolver.resolvedCategoryId(for: self)
        if categoryId == nil { return AppLocalizer.text("Uncategorized") }
        return CategoryRule.name(for: categoryId)
    }

    func updateRemoteFields(from item: GitHubStarredItem) {
        let repo = item.repo
        name = repo.name
        fullName = repo.fullName
        descriptionText = repo.description
        htmlURL = repo.htmlURL
        stars = repo.stargazersCount
        forks = repo.forks
        language = repo.language
        topicsJSON = Self.encodeTopics(repo.topics)
        ownerLogin = repo.owner.login
        ownerAvatarURL = repo.owner.avatarURL
        createdAt = repo.createdAt
        updatedAt = repo.updatedAt
        pushedAt = repo.pushedAt
        starredAt = item.starredAt
    }

    func updateImportedFields(from record: StarRepositoryRecord) {
        name = record.name
        fullName = record.fullName
        descriptionText = record.descriptionText
        htmlURL = record.htmlURL
        stars = record.stars
        forks = record.forks
        language = record.language
        topicsJSON = Self.encodeTopics(record.topics)
        ownerLogin = record.ownerLogin
        ownerAvatarURL = record.ownerAvatarURL
        createdAt = record.createdAt
        updatedAt = record.updatedAt
        pushedAt = record.pushedAt
        starredAt = record.starredAt
        manualCategoryId = record.manualCategoryId
        notes = record.notes
        lastViewedAt = record.lastViewedAt
    }

    static func encodeTopics(_ topics: [String]) -> String {
        guard let data = try? JSONEncoder().encode(topics),
              let string = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return string
    }
}
