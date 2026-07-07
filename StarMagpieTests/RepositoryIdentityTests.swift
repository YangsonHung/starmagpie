import XCTest
@testable import StarMagpie

final class RepositoryIdentityTests: XCTestCase {
    func testParsesValidFullName() throws {
        let identity = try RepositoryIdentity(fullName: "octocat/Hello-World")

        XCTAssertEqual(identity.owner, "octocat")
        XCTAssertEqual(identity.name, "Hello-World")
        XCTAssertEqual(identity.fullName, "octocat/Hello-World")
    }

    func testRejectsInvalidFullName() {
        XCTAssertThrowsError(try RepositoryIdentity(fullName: "octocat")) { error in
            XCTAssertEqual(error as? RepositoryReadmeError, .invalidRepositoryName)
        }
        XCTAssertThrowsError(try RepositoryIdentity(fullName: "/Hello-World")) { error in
            XCTAssertEqual(error as? RepositoryReadmeError, .invalidRepositoryName)
        }
        XCTAssertThrowsError(try RepositoryIdentity(fullName: "octocat/")) { error in
            XCTAssertEqual(error as? RepositoryReadmeError, .invalidRepositoryName)
        }
    }
}
