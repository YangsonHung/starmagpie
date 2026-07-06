import Foundation

struct GitHubUser: Decodable, Equatable {
    let id: Int64
    let login: String
    let name: String?
    let avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case login
        case name
        case avatarURL = "avatar_url"
    }
}

struct GitHubOwnerDTO: Decodable, Equatable {
    let login: String
    let avatarURL: String

    enum CodingKeys: String, CodingKey {
        case login
        case avatarURL = "avatar_url"
    }
}

struct GitHubRepoDTO: Decodable, Equatable {
    let id: Int64
    let name: String
    let fullName: String
    let description: String?
    let htmlURL: String
    let stargazersCount: Int
    let forksCount: Int
    let forks: Int
    let language: String?
    let createdAt: Date
    let updatedAt: Date
    let pushedAt: Date?
    let owner: GitHubOwnerDTO
    let topics: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case description
        case htmlURL = "html_url"
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
        case forks
        case language
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case pushedAt = "pushed_at"
        case owner
        case topics
    }

    init(
        id: Int64,
        name: String,
        fullName: String,
        description: String?,
        htmlURL: String,
        stargazersCount: Int,
        forksCount: Int,
        forks: Int,
        language: String?,
        createdAt: Date,
        updatedAt: Date,
        pushedAt: Date?,
        owner: GitHubOwnerDTO,
        topics: [String]
    ) {
        self.id = id
        self.name = name
        self.fullName = fullName
        self.description = description
        self.htmlURL = htmlURL
        self.stargazersCount = stargazersCount
        self.forksCount = forksCount
        self.forks = forks
        self.language = language
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.pushedAt = pushedAt
        self.owner = owner
        self.topics = topics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        fullName = try container.decode(String.self, forKey: .fullName)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        htmlURL = try container.decode(String.self, forKey: .htmlURL)
        stargazersCount = try container.decode(Int.self, forKey: .stargazersCount)
        forksCount = try container.decodeIfPresent(Int.self, forKey: .forksCount) ?? 0
        forks = try container.decodeIfPresent(Int.self, forKey: .forks) ?? forksCount
        language = try container.decodeIfPresent(String.self, forKey: .language)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        pushedAt = try container.decodeIfPresent(Date.self, forKey: .pushedAt)
        owner = try container.decode(GitHubOwnerDTO.self, forKey: .owner)
        topics = try container.decodeIfPresent([String].self, forKey: .topics) ?? []
    }
}

struct GitHubStarredItem: Decodable, Equatable {
    let starredAt: Date?
    let repo: GitHubRepoDTO

    enum CodingKeys: String, CodingKey {
        case starredAt = "starred_at"
        case repo
    }

    init(starredAt: Date?, repo: GitHubRepoDTO) {
        self.starredAt = starredAt
        self.repo = repo
    }

    init(from decoder: Decoder) throws {
        let container = try? decoder.container(keyedBy: CodingKeys.self)
        if let container, container.contains(.repo) {
            starredAt = try container.decodeIfPresent(Date.self, forKey: .starredAt)
            repo = try container.decode(GitHubRepoDTO.self, forKey: .repo)
        } else {
            starredAt = nil
            repo = try GitHubRepoDTO(from: decoder)
        }
    }
}

extension JSONDecoder {
    static var github: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

