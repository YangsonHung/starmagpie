import XCTest
@testable import StarMagpie

final class ReadmeURLMapperTests: XCTestCase {
    func testMapsRawReadmeAssetLinksToGitHubBlobPages() {
        let rawURL = URL(string: "https://raw.githubusercontent.com/anomalyco/opencode/HEAD/README.zh.md#install")!

        let mappedURL = ReadmeURLMapper.externalURL(for: rawURL)

        XCTAssertEqual(
            mappedURL.absoluteString,
            "https://github.com/anomalyco/opencode/blob/HEAD/README.zh.md#install"
        )
    }

    func testMapsRawRepositoryRootToGitHubTreePage() {
        let rawURL = URL(string: "https://raw.githubusercontent.com/anomalyco/opencode/HEAD/#readme")!

        let mappedURL = ReadmeURLMapper.externalURL(for: rawURL)

        XCTAssertEqual(
            mappedURL.absoluteString,
            "https://github.com/anomalyco/opencode/tree/HEAD#readme"
        )
    }

    func testKeepsExternalURLsUnchanged() {
        let externalURL = URL(string: "https://opencode.ai")!

        XCTAssertEqual(ReadmeURLMapper.externalURL(for: externalURL), externalURL)
    }
}
