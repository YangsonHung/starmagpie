import Foundation

protocol HTTPSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPSession {}

enum GitHubClientError: LocalizedError, Equatable {
    case invalidToken
    case rateLimitExceeded(resetDate: Date?)
    case invalidResponse
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return AppLocalizer.text("GitHub token is invalid or expired")
        case .rateLimitExceeded(let resetDate):
            if let resetDate {
                return AppLocalizer.text(
                    "GitHub API rate limit exceeded. Resets at %@",
                    resetDate.formatted(date: .abbreviated, time: .shortened)
                )
            }
            return AppLocalizer.text("GitHub API rate limit exceeded")
        case .invalidResponse:
            return AppLocalizer.text("GitHub API returned an invalid response")
        case .httpStatus(let status):
            return AppLocalizer.text("GitHub API request failed: HTTP %lld", Int64(status))
        }
    }
}

final class GitHubClient {
    private let token: String
    private let baseURL: URL
    private let session: HTTPSession
    private let pageDelayNanoseconds: UInt64

    init(
        token: String,
        baseURL: URL = URL(string: "https://api.github.com")!,
        session: HTTPSession = URLSession.shared,
        pageDelayNanoseconds: UInt64 = 100_000_000
    ) {
        self.token = token
        self.baseURL = baseURL
        self.session = session
        self.pageDelayNanoseconds = pageDelayNanoseconds
    }

    func validateToken() async throws -> GitHubUser {
        let request = makeRequest(pathComponents: ["user"], accept: "application/vnd.github.v3+json")
        let data = try await perform(request)
        return try JSONDecoder.github.decode(GitHubUser.self, from: data)
    }

    func fetchAllStarredRepositories() async throws -> [GitHubStarredItem] {
        var page = 1
        let perPage = 100
        var allItems: [GitHubStarredItem] = []

        while true {
            let pageItems = try await fetchStarredRepositories(page: page, perPage: perPage)
            allItems.append(contentsOf: pageItems)

            if pageItems.count < perPage {
                break
            }

            page += 1
            if pageDelayNanoseconds > 0 {
                try await Task.sleep(nanoseconds: pageDelayNanoseconds)
            }
        }

        return allItems
    }

    func unstar(owner: String, repo: String) async throws {
        let request = makeRequest(
            pathComponents: ["user", "starred", owner, repo],
            method: "DELETE",
            accept: "application/vnd.github.v3+json"
        )
        _ = try await perform(request, acceptsNoContent: true)
    }

    func fetchReadmeHTML(owner: String, repo: String) async throws -> RepositoryReadme {
        let request = makeRequest(
            pathComponents: ["repos", owner, repo, "readme"],
            accept: "application/vnd.github.html+json"
        )
        let data = try await perform(request, notFoundError: RepositoryReadmeError.notFound)
        guard let html = String(data: data, encoding: .utf8) else {
            throw RepositoryReadmeError.invalidEncoding
        }

        let readmeBaseURL = URL(string: "https://raw.githubusercontent.com/\(owner)/\(repo)/HEAD/")!
        return RepositoryReadme(
            html: html,
            baseURL: readmeBaseURL
        )
    }

    private func fetchStarredRepositories(page: Int, perPage: Int) async throws -> [GitHubStarredItem] {
        let queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "sort", value: "updated")
        ]
        let request = makeRequest(
            pathComponents: ["user", "starred"],
            queryItems: queryItems,
            accept: "application/vnd.github.star+json"
        )
        let data = try await perform(request)
        return try JSONDecoder.github.decode([GitHubStarredItem].self, from: data)
    }

    private func makeRequest(
        pathComponents: [String],
        queryItems: [URLQueryItem] = [],
        method: String = "GET",
        accept: String
    ) -> URLRequest {
        var url = baseURL
        pathComponents.forEach { url.appendPathComponent($0) }

        if !queryItems.isEmpty, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.queryItems = queryItems
            url = components.url ?? url
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(accept, forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        return request
    }

    private func perform(
        _ request: URLRequest,
        acceptsNoContent: Bool = false,
        notFoundError: Error? = nil
    ) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubClientError.invalidResponse
        }

        if httpResponse.statusCode == 204, acceptsNoContent {
            return Data()
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404, let notFoundError {
                throw notFoundError
            }
            if httpResponse.statusCode == 401 {
                throw GitHubClientError.invalidToken
            }
            if httpResponse.statusCode == 403,
               httpResponse.value(forHTTPHeaderField: "X-RateLimit-Remaining") == "0" {
                let resetDate = httpResponse
                    .value(forHTTPHeaderField: "X-RateLimit-Reset")
                    .flatMap(TimeInterval.init)
                    .map { Date(timeIntervalSince1970: $0) }
                throw GitHubClientError.rateLimitExceeded(resetDate: resetDate)
            }
            throw GitHubClientError.httpStatus(httpResponse.statusCode)
        }

        return data
    }
}
