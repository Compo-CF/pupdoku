import XCTest
@testable import Pupdoku

/// Review prompt gate (guideline 5.6.3): never on a fresh install, in the first
/// session, or before real play.
final class ReviewManagerTests: XCTestCase {
    private let day: Double = 86_400
    private let first: Double = 100 * 86_400

    private func ok(wins: Int = 6, launches: Int = 2, now: Double? = nil,
                    lastVersion: String? = nil, lastDate: Double = 0) -> Bool {
        ReviewManager.eligible(totalWins: wins, launches: launches, firstLaunchAt: first,
                               lastVersion: lastVersion, lastDate: lastDate,
                               version: "3.2.2", now: now ?? first + 3 * day)
    }

    func testAllConditionsMet() {
        XCTAssertTrue(ok())
        XCTAssertTrue(ok(wins: 18))
    }

    func testNeverEarly() {
        XCTAssertFalse(ok(wins: 2), "win #2 is no longer a milestone")
        XCTAssertFalse(ok(wins: 6, launches: 1, now: first + 600), "fresh install, first session")
        XCTAssertFalse(ok(launches: 1))
        XCTAssertFalse(ok(now: first + 1.9 * day))
        XCTAssertTrue(ok(now: first + 2 * day))
        XCTAssertFalse(ReviewManager.eligible(totalWins: 6, launches: 5, firstLaunchAt: 0, lastVersion: nil,
                                              lastDate: 0, version: "3.2.2", now: first))
        XCTAssertTrue(ReviewManager.milestones.min()! >= 6)
    }

    func testFloors() {
        XCTAssertFalse(ok(lastVersion: "3.2.2"), "once per version")
        XCTAssertFalse(ok(wins: 18, now: first + 50 * day, lastVersion: "3.2.1", lastDate: first + 3 * day), "90-day floor")
        XCTAssertTrue(ok(wins: 18, now: first + 94 * day, lastVersion: "3.2.1", lastDate: first + 3 * day))
    }
}
