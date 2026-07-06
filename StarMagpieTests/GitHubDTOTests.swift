import XCTest
@testable import StarMagpie

final class GitHubDTOTests: XCTestCase {
    func testDecodesStarredAtWrapperResponse() throws {
        let json = """
        [
          {
            "starred_at": "2024-01-02T03:04:05Z",
            "repo": {
              "id": 42,
              "name": "Hello",
              "full_name": "octocat/Hello",
              "description": "A test repository",
              "html_url": "https://github.com/octocat/Hello",
              "stargazers_count": 123,
              "forks_count": 7,
              "forks": 7,
              "language": "Swift",
              "created_at": "2023-01-01T00:00:00Z",
              "updated_at": "2024-01-01T00:00:00Z",
              "pushed_at": "2024-01-01T01:00:00Z",
              "owner": {
                "login": "octocat",
                "avatar_url": "https://avatars.githubusercontent.com/u/1?v=4"
              },
              "topics": ["macos", "swiftui"]
            }
          }
        ]
        """

        let items = try JSONDecoder.github.decode([GitHubStarredItem].self, from: Data(json.utf8))

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].repo.id, 42)
        XCTAssertEqual(items[0].repo.fullName, "octocat/Hello")
        XCTAssertEqual(items[0].repo.topics, ["macos", "swiftui"])
        XCTAssertNotNil(items[0].starredAt)
    }

    func testDecodesPlainRepositoryResponse() throws {
        let json = """
        [
          {
            "id": 7,
            "name": "Plain",
            "full_name": "octocat/Plain",
            "description": null,
            "html_url": "https://github.com/octocat/Plain",
            "stargazers_count": 1,
            "forks_count": 0,
            "language": null,
            "created_at": "2023-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z",
            "pushed_at": null,
            "owner": {
              "login": "octocat",
              "avatar_url": "https://avatars.githubusercontent.com/u/1?v=4"
            }
          }
        ]
        """

        let items = try JSONDecoder.github.decode([GitHubStarredItem].self, from: Data(json.utf8))

        XCTAssertEqual(items[0].repo.id, 7)
        XCTAssertNil(items[0].starredAt)
        XCTAssertEqual(items[0].repo.topics, [])
        XCTAssertEqual(items[0].repo.forks, 0)
    }
}

