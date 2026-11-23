import XCTest
@testable import Pupdoku

/// Covers the v3.0 Bones economy: earning, spending, themes, event passes, the
/// Starter Pack, and subscription-aware hints.
@MainActor
final class EconomyTests: XCTestCase {

    private func makeStore() -> GameStore {
        GameStore(state: GameState(), persistence: Persistence.inMemory())
    }

    // MARK: - Earning

    func testBonesAwardedOnWin() {
        var s = GameState()
        let before = s.bones
        let spec = PuzzleSpec(difficulty: .medium)
        _ = s.recordWin(spec: spec, elapsed: 60, mistakes: 0, hintsUsed: 0, isDaily: false, todayEpochDay: 100)
        let expected = GameState.bonesForWin(spec: spec, mistakes: 0, hintsUsed: 0, isDaily: false)
        XCTAssertEqual(s.bones, before + expected)
        XCTAssertEqual(s.lastWinBones, expected)
        XCTAssertGreaterThan(expected, 0)
    }

    func testPerfectAndDailyBonuses() {
        let base = GameState.bonesForWin(spec: .init(difficulty: .puppy), mistakes: 1, hintsUsed: 1, isDaily: false)
        let perfect = GameState.bonesForWin(spec: .init(difficulty: .puppy), mistakes: 0, hintsUsed: 0, isDaily: false)
        let daily = GameState.bonesForWin(spec: .init(difficulty: .puppy), mistakes: 1, hintsUsed: 1, isDaily: true)
        XCTAssertGreaterThan(perfect, base)
        XCTAssertGreaterThan(daily, base)
    }

    // MARK: - Spending

    func testSpendBones() {
        let store = makeStore()
        store.addBones(100)
        XCTAssertEqual(store.bones, 100)
        XCTAssertTrue(store.spendBones(30))
        XCTAssertEqual(store.bones, 70)
        XCTAssertFalse(store.spendBones(1000))
        XCTAssertEqual(store.bones, 70)
    }

    // MARK: - Themes

    func testBuyThemeSpendsBonesAndOwns() {
        let store = makeStore()
        let midnight = ThemeCatalog.theme("midnight")
        store.addBones(midnight.priceBones + 50)
        XCTAssertTrue(store.buyTheme(midnight))
        XCTAssertTrue(store.ownsTheme("midnight"))
        XCTAssertEqual(store.bones, 50)
        // Re-buying is a no-op success and does not charge again.
        XCTAssertTrue(store.buyTheme(midnight))
        XCTAssertEqual(store.bones, 50)
    }

    func testBuyThemeInsufficientBonesFails() {
        let store = makeStore()
        XCTAssertFalse(store.buyTheme(ThemeCatalog.theme("neon")))
        XCTAssertFalse(store.ownsTheme("neon"))
    }

    func testSelectThemeRequiresOwnership() {
        let store = makeStore()
        store.selectTheme("neon")                 // not owned -> ignored
        XCTAssertEqual(store.selectedThemeId, "classic")
        store.addBones(1000)
        _ = store.buyTheme(ThemeCatalog.theme("neon"))
        store.selectTheme("neon")
        XCTAssertEqual(store.selectedThemeId, "neon")
    }

    // MARK: - Event passes

    func testUnlockEventPassAddsPassAndTheme() {
        let store = makeStore()
        store.unlockEventPass(productId: IAPManager.eventSpookyProductId)
        XCTAssertTrue(store.ownsEventPass("eventpass.spooky2026"))
        XCTAssertTrue(store.ownsTheme("spooky"))
    }

    func testBuyEventPassWithBones() {
        let store = makeStore()
        let pass = EventPassCatalog.pass("eventpass.winter2026")!
        store.addBones(pass.bonesPrice)
        XCTAssertTrue(store.buyEventPassWithBones(pass))
        XCTAssertEqual(store.bones, 0)
        XCTAssertTrue(store.ownsEventPass(pass.id))
        XCTAssertTrue(store.ownsTheme("winter"))
    }

    // MARK: - Starter Pack

    func testStarterPackGrants() {
        let store = makeStore()
        store.applyStarterPack()
        XCTAssertEqual(store.bones, 600)
        XCTAssertTrue(store.ownsTheme("midnight"))
    }

    // MARK: - Hints

    func testHintFromBalanceDecrements() async {
        let store = makeStore()
        await store.startNewGame(spec: .init(difficulty: .puppy))
        let before = store.hintBalance
        XCTAssertTrue(store.useHintFromBalance())
        XCTAssertEqual(store.hintBalance, before - 1)
    }

    func testSubscriptionGivesUnlimitedHints() async {
        let store = makeStore()
        await store.startNewGame(spec: .init(difficulty: .puppy))
        store.subscriptionActive = true
        let before = store.hintBalance
        XCTAssertTrue(store.useHintFromBalance())
        XCTAssertTrue(store.useHintFromBalance())
        XCTAssertEqual(store.hintBalance, before, "subscription must not consume the hint balance")
    }

    func testUseHintWithBonesSpends() async {
        let store = makeStore()
        await store.startNewGame(spec: .init(difficulty: .puppy))
        store.addBones(50)
        XCTAssertTrue(store.useHintWithBones())
        XCTAssertEqual(store.bones, 50 - GameStore.hintBonesCost)
    }

    // MARK: - Event Challenge (New Year Pup Challenge, 3.3)

    func testChallengeCountsOnlyInWindowAndOncePerDay() {
        let c = EventChallengeCatalog.newYear2027
        var s = GameState()
        let spec = PuzzleSpec(difficulty: .medium)
        _ = s.recordWin(spec: spec, elapsed: 60, mistakes: 0, hintsUsed: 0, isDaily: true, todayEpochDay: c.startEpochDay - 1)
        XCTAssertEqual(s.challengeProgress(c), 0)
        _ = s.recordWin(spec: spec, elapsed: 60, mistakes: 0, hintsUsed: 0, isDaily: true, todayEpochDay: c.startEpochDay)
        _ = s.recordWin(spec: spec, elapsed: 60, mistakes: 0, hintsUsed: 0, isDaily: true, todayEpochDay: c.startEpochDay)
        _ = s.recordWin(spec: spec, elapsed: 60, mistakes: 0, hintsUsed: 0, isDaily: false, todayEpochDay: c.startEpochDay + 1)
        XCTAssertEqual(s.challengeProgress(c), 1)
        _ = s.recordWin(spec: spec, elapsed: 60, mistakes: 0, hintsUsed: 0, isDaily: true, todayEpochDay: c.endEpochDay)
        XCTAssertEqual(s.challengeProgress(c), 1)
    }

    func testChallengeRewardGrantedOnceAtGoal() {
        let c = EventChallengeCatalog.newYear2027
        var s = GameState()
        let spec = PuzzleSpec(difficulty: .medium)
        for d in 0..<(c.goal - 1) {
            _ = s.recordWin(spec: spec, elapsed: 60, mistakes: 0, hintsUsed: 0, isDaily: true, todayEpochDay: c.startEpochDay + d)
        }
        XCTAssertFalse(s.ownedThemes.contains(c.rewardThemeId))
        let before = s.bones
        _ = s.recordWin(spec: spec, elapsed: 60, mistakes: 0, hintsUsed: 0, isDaily: true, todayEpochDay: c.startEpochDay + c.goal)
        XCTAssertTrue(s.isChallengeComplete(c))
        XCTAssertTrue(s.ownedThemes.contains(c.rewardThemeId))
        let daily = GameState.bonesForWin(spec: spec, mistakes: 0, hintsUsed: 0, isDaily: true)
        XCTAssertEqual(s.bones, before + daily + c.rewardBones)
        let after = s.bones
        _ = s.recordWin(spec: spec, elapsed: 60, mistakes: 0, hintsUsed: 0, isDaily: true, todayEpochDay: c.startEpochDay + c.goal + 1)
        XCTAssertEqual(s.bones, after + daily)   // no second reward
        XCTAssertEqual(ThemeCatalog.costumeId(for: c.rewardThemeId), "newyear")
    }

    func testOldSaveWithoutChallengeKeysStillDecodes() throws {
        var legacy = GameState()
        legacy.bones = 42
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(legacy)) as! [String: Any]
        json.removeValue(forKey: "challengeDays"); json.removeValue(forKey: "completedChallenges"); json.removeValue(forKey: "lastChallengeNote")
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoded = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertEqual(decoded.bones, 42)
    }

    func testNewYearDeepLinkRoutesToChallenge() {
        let r = DeepLinkRouter()
        r.handle(URL(string: "pupdoku://event/newyear")!)
        XCTAssertEqual(r.pendingRoute, .challenge("challenge.newyear2027"))
        r.pendingRoute = nil
        r.handle(URL(string: "pupdoku://event/winter")!)
        XCTAssertEqual(r.pendingRoute, .shop)
    }
}
