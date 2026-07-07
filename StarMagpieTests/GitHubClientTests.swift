import Foundation
import XCTest
@testable import StarMagpie

final class GitHubClientTests: XCTestCase {
    func testFetchAllStarredRepositoriesPaginatesUntilShortPage() async throws {
        let firstPage = makeStarredPage(count: 100, startingID: 1)
        let secondPage = makeStarredPage(count: 2, startingID: 101)
        let session = MockHTTPSession(responses: [
            .success(json: firstPage),
            .success(json: secondPage)
        ])
        let client = GitHubClient(token: "token", session: session, pageDelayNanoseconds: 0)

        let items = try await client.fetchAllStarredRepositories()

        XCTAssertEqual(items.count, 102)
        XCTAssertEqual(session.requests.count, 2)
        XCTAssertTrue(session.requests[0].url?.absoluteString.contains("page=1") == true)
        XCTAssertTrue(session.requests[1].url?.absoluteString.contains("page=2") == true)
        XCTAssertEqual(session.requests[0].value(forHTTPHeaderField: "Accept"), "application/vnd.github.star+json")
    }

    func testFetchAllStarredRepositoriesReturnsEmptyPage() async throws {
        let session = MockHTTPSession(responses: [.success(json: "[]")])
        let client = GitHubClient(token: "token", session: session, pageDelayNanoseconds: 0)

        let items = try await client.fetchAllStarredRepositories()

        XCTAssertEqual(items.count, 0)
        XCTAssertEqual(session.requests.count, 1)
    }

    func testValidateTokenThrowsInvalidTokenOn401() async {
        let session = MockHTTPSession(responses: [.failure(status: 401)])
        let client = GitHubClient(token: "bad", session: session, pageDelayNanoseconds: 0)

        do {
            _ = try await client.validateToken()
            XCTFail("Expected invalid token error")
        } catch {
            XCTAssertEqual(error as? GitHubClientError, .invalidToken)
        }
    }

    func testUnstarUsesAuthenticatedStarredEndpoint() async throws {
        let session = MockHTTPSession(responses: [.success(json: "", status: 204)])
        let client = GitHubClient(
            token: "token",
            baseURL: URL(string: "https://api.example.test")!,
            session: session,
            pageDelayNanoseconds: 0
        )

        try await client.unstar(owner: "octocat", repo: "Hello-World")

        XCTAssertEqual(session.requests.count, 1)
        XCTAssertEqual(session.requests[0].httpMethod, "DELETE")
        XCTAssertEqual(session.requests[0].url?.path, "/user/starred/octocat/Hello-World")
        XCTAssertEqual(session.requests[0].value(forHTTPHeaderField: "Accept"), "application/vnd.github+json")
        XCTAssertEqual(session.requests[0].value(forHTTPHeaderField: "X-GitHub-Api-Version"), "2022-11-28")
        XCTAssertEqual(session.requests[0].value(forHTTPHeaderField: "Authorization"), "Bearer token")
    }

    func testUnstarMapsForbiddenToPermissionDenied() async {
        let session = MockHTTPSession(responses: [.failure(status: 403)])
        let client = GitHubClient(token: "token", session: session, pageDelayNanoseconds: 0)

        do {
            try await client.unstar(owner: "octocat", repo: "Hello-World")
            XCTFail("Expected permission denied error")
        } catch {
            XCTAssertEqual(error as? GitHubClientError, .permissionDenied(detail: nil))
        }
    }

    func testUnstarPermissionDeniedIncludesGitHubResponseDetails() async {
        let session = MockHTTPSession(responses: [
            .failure(
                json: #"{"message":"Resource not accessible by personal access token"}"#,
                status: 403,
                headers: ["X-Accepted-GitHub-Permissions": "starring=write; metadata=read"]
            )
        ])
        let client = GitHubClient(token: "token", session: session, pageDelayNanoseconds: 0)

        do {
            try await client.unstar(owner: "octocat", repo: "Hello-World")
            XCTFail("Expected permission denied error")
        } catch {
            XCTAssertEqual(
                error as? GitHubClientError,
                .permissionDenied(
                    detail: "Resource not accessible by personal access token X-Accepted-GitHub-Permissions: starring=write; metadata=read"
                )
            )
        }
    }

    func testRateLimitedForbiddenMapsToRateLimitExceeded() async {
        let session = MockHTTPSession(responses: [
            .failure(status: 403, headers: [
                "X-RateLimit-Remaining": "0",
                "X-RateLimit-Reset": "1700000000"
            ])
        ])
        let client = GitHubClient(token: "token", session: session, pageDelayNanoseconds: 0)

        do {
            _ = try await client.fetchAllStarredRepositories()
            XCTFail("Expected rate limit error")
        } catch {
            XCTAssertEqual(
                error as? GitHubClientError,
                .rateLimitExceeded(resetDate: Date(timeIntervalSince1970: 1_700_000_000))
            )
        }
    }

    func testFetchReadmeHTMLUsesRepositoryReadmeEndpoint() async throws {
        let session = MockHTTPSession(responses: [.success(json: "<h1>Hello</h1>")])
        let client = GitHubClient(
            token: "token",
            baseURL: URL(string: "https://api.example.test")!,
            session: session,
            pageDelayNanoseconds: 0
        )

        let readme = try await client.fetchReadmeHTML(owner: "octocat", repo: "Hello-World")

        XCTAssertEqual(readme.html, "<h1>Hello</h1>")
        XCTAssertEqual(readme.baseURL.absoluteString, "https://raw.githubusercontent.com/octocat/Hello-World/HEAD/")
        XCTAssertEqual(session.requests.count, 1)
        XCTAssertEqual(session.requests[0].url?.path, "/repos/octocat/Hello-World/readme")
        XCTAssertEqual(session.requests[0].value(forHTTPHeaderField: "Accept"), "application/vnd.github.html+json")
        XCTAssertEqual(session.requests[0].value(forHTTPHeaderField: "X-GitHub-Api-Version"), "2022-11-28")
        XCTAssertEqual(session.requests[0].value(forHTTPHeaderField: "Authorization"), "Bearer token")
    }

    func testFetchReadmeHTMLMaps404ToReadmeNotFound() async {
        let session = MockHTTPSession(responses: [.failure(status: 404)])
        let client = GitHubClient(token: "token", session: session, pageDelayNanoseconds: 0)

        do {
            _ = try await client.fetchReadmeHTML(owner: "octocat", repo: "Missing")
            XCTFail("Expected README not found error")
        } catch {
            XCTAssertEqual(error as? RepositoryReadmeError, .notFound)
        }
    }

    func testNetworkErrorIsPropagated() async {
        struct NetworkFailure: Error {}
        let session = MockHTTPSession(responses: [.networkError(NetworkFailure())])
        let client = GitHubClient(token: "token", session: session, pageDelayNanoseconds: 0)

        do {
            _ = try await client.fetchAllStarredRepositories()
            XCTFail("Expected network error")
        } catch {
            XCTAssertTrue(error is NetworkFailure)
        }
    }

    private func makeStarredPage(count: Int, startingID: Int64) -> String {
        let items = (0..<count).map { offset in
            let id = startingID + Int64(offset)
            return """
            {
              "starred_at": "2024-01-02T03:04:05Z",
              "repo": {
                "id": \(id),
                "name": "Repo\(id)",
                "full_name": "octocat/Repo\(id)",
                "description": "Repository \(id)",
                "html_url": "https://github.com/octocat/Repo\(id)",
                "stargazers_count": \(id),
                "forks_count": 1,
                "forks": 1,
                "language": "Swift",
                "created_at": "2023-01-01T00:00:00Z",
                "updated_at": "2024-01-01T00:00:00Z",
                "pushed_at": "2024-01-01T01:00:00Z",
                "owner": {
                  "login": "octocat",
                  "avatar_url": "https://avatars.githubusercontent.com/u/1?v=4"
                },
                "topics": ["swift"]
              }
            }
            """
        }
        return "[\(items.joined(separator: ","))]"
    }
}

private final class MockHTTPSession: HTTPSession {
    enum Response {
        case success(json: String, status: Int = 200, headers: [String: String] = [:])
        case failure(json: String = "", status: Int, headers: [String: String] = [:])
        case networkError(Error)
    }

    private(set) var requests: [URLRequest] = []
    private var responses: [Response]

    init(responses: [Response]) {
        self.responses = responses
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        let response = responses.removeFirst()
        switch response {
        case .success(let json, let status, let headers):
            return (Data(json.utf8), httpResponse(for: request, status: status, headers: headers))
        case .failure(let json, let status, let headers):
            return (Data(json.utf8), httpResponse(for: request, status: status, headers: headers))
        case .networkError(let error):
            throw error
        }
    }

    private func httpResponse(for request: URLRequest, status: Int, headers: [String: String]) -> HTTPURLResponse {
        HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: nil,
            headerFields: headers
        )!
    }
}
