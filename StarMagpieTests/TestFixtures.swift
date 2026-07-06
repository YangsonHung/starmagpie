import Foundation
@testable import StarMagpie

enum TestFixtures {
    static let date = Date(timeIntervalSince1970: 1_704_067_200)

    static func owner(login: String = "octocat") -> GitHubOwnerDTO {
        GitHubOwnerDTO(login: login, avatarURL: "https://avatars.githubusercontent.com/u/1?v=4")
    }

    static func repo(
        id: Int64,
        name: String,
        fullName: String? = nil,
        description: String? = nil,
        stars: Int = 10,
        forks: Int = 2,
        language: String? = "Swift",
        topics: [String] = []
    ) -> GitHubRepoDTO {
        GitHubRepoDTO(
            id: id,
            name: name,
            fullName: fullName ?? "octocat/\(name)",
            description: description,
            htmlURL: "https://github.com/\(fullName ?? "octocat/\(name)")",
            stargazersCount: stars,
            forksCount: forks,
            forks: forks,
            language: language,
            createdAt: date,
            updatedAt: date.addingTimeInterval(60),
            pushedAt: date.addingTimeInterval(120),
            owner: owner(),
            topics: topics
        )
    }

    static func starred(
        id: Int64,
        name: String,
        fullName: String? = nil,
        description: String? = nil,
        stars: Int = 10,
        forks: Int = 2,
        language: String? = "Swift",
        topics: [String] = [],
        starredAt: Date? = date
    ) -> GitHubStarredItem {
        GitHubStarredItem(
            starredAt: starredAt,
            repo: repo(
                id: id,
                name: name,
                fullName: fullName,
                description: description,
                stars: stars,
                forks: forks,
                language: language,
                topics: topics
            )
        )
    }
}

