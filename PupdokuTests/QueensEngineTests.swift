import XCTest
@testable import Pupdoku

final class QueensEngineTests: XCTestCase {

    private func allSizes() -> [Difficulty] { Difficulty.allCases }

    // MARK: - Generation validity + uniqueness

    func testGeneratedPuzzlesAreUniqueForEverySize() {
        for d in allSizes() {
            let spec = PuzzleSpec(difficulty: d)
            let puzzle = QueensPuzzle.generate(spec: spec, seed: 12345)
            XCTAssertEqual(puzzle.n, d.n)
            XCTAssertEqual(QueensSolver.countSolutions(n: puzzle.n, regionOf: puzzle.regionOf, limit: 2), 1,
                           "\(d.sizeLabel) must have exactly one solution")
        }
    }

    func testSolverFindsTheStatedSolution() {
        for d in allSizes() {
            let puzzle = QueensPuzzle.generate(spec: PuzzleSpec(difficulty: d), seed: 42)
            let solved = QueensSolver.solve(n: puzzle.n, regionOf: puzzle.regionOf)
            XCTAssertEqual(solved, puzzle.solutionCols, "\(d.sizeLabel) solver should match the generated solution")
        }
    }

    func testSolutionSatisfiesAllConstraints() {
        for d in allSizes() {
            let p = QueensPuzzle.generate(spec: PuzzleSpec(difficulty: d), seed: 7)
            let n = p.n
            var cols = Set<Int>(), regions = Set<Int>()
            for row in 0..<n {
                let col = p.solutionCols[row]
                cols.insert(col)
                regions.insert(p.region(at: row, col))
                if row > 0 { XCTAssertGreaterThanOrEqual(abs(col - p.solutionCols[row - 1]), 2, "no touching") }
            }
            XCTAssertEqual(cols.count, n, "one per column")
            XCTAssertEqual(regions.count, n, "one per region")
        }
    }

    func testRegionsCoverBoardWithNRegions() {
        for d in allSizes() {
            let p = QueensPuzzle.generate(spec: PuzzleSpec(difficulty: d), seed: 99)
            XCTAssertEqual(p.regionOf.count, p.n * p.n)
            XCTAssertFalse(p.regionOf.contains(-1), "every cell assigned")
            XCTAssertEqual(Set(p.regionOf).count, p.n, "exactly N regions")
        }
    }

    // MARK: - Determinism (Daily fairness)

    func testSameSeedProducesSameBoard() {
        let spec = PuzzleSpec(difficulty: .hard)
        let a = QueensPuzzle.generate(spec: spec, seed: 2026)
        let b = QueensPuzzle.generate(spec: spec, seed: 2026)
        XCTAssertEqual(a.regionOf, b.regionOf)
        XCTAssertEqual(a.solutionCols, b.solutionCols)
    }

    func testDailySeedIsStablePerDay() {
        let date = Date(timeIntervalSince1970: 1_770_000_000)
        XCTAssertEqual(SeededRNG.dailySeed(for: date), SeededRNG.dailySeed(for: date))
    }

    // MARK: - Session behavior

    @MainActor
    func testCycleGoesEmptyMarkedPuppyEmpty() {
        let p = QueensPuzzle.generate(spec: PuzzleSpec(difficulty: .puppy), seed: 5)
        let s = QueensSession(puzzle: p)
        XCTAssertEqual(s.state(at: 0), .empty)
        s.cycle(0); XCTAssertEqual(s.state(at: 0), .marked)
        s.cycle(0); XCTAssertEqual(s.state(at: 0), .puppy)
        s.cycle(0); XCTAssertEqual(s.state(at: 0), .empty)
    }

    @MainActor
    func testPlacingTheSolutionWins() {
        let p = QueensPuzzle.generate(spec: PuzzleSpec(difficulty: .puppy), seed: 6)
        let s = QueensSession(puzzle: p)
        for flat in p.solutionIndices { s.cycle(flat); s.cycle(flat) } // empty -> marked -> puppy
        XCTAssertEqual(s.status, .won)
        XCTAssertEqual(s.puppyCount, p.n)
        XCTAssertTrue(s.conflicts.isEmpty)
    }

    @MainActor
    func testConflictsAreDetected() {
        let p = QueensPuzzle.generate(spec: PuzzleSpec(difficulty: .easy), seed: 8)
        let s = QueensSession(puzzle: p)
        // Two puppies in row 0 must conflict.
        let a = 0, b = 2
        s.cycle(a); s.cycle(a)
        s.cycle(b); s.cycle(b)
        XCTAssertTrue(s.conflicts.contains(a) && s.conflicts.contains(b))
        XCTAssertNotEqual(s.status, .won)
    }

    @MainActor
    func testHintRevealsASolutionCell() {
        let p = QueensPuzzle.generate(spec: PuzzleSpec(difficulty: .medium), seed: 8)
        let s = QueensSession(puzzle: p)
        XCTAssertTrue(s.useHint())
        XCTAssertEqual(s.hintsUsed, 1)
        let placed = (0..<(p.n * p.n)).filter { s.state(at: $0) == .puppy }
        XCTAssertEqual(placed.count, 1)
        XCTAssertTrue(p.solutionIndices.contains(placed[0]))
    }

    @MainActor
    func testUndoRestoresPreviousState() {
        let p = QueensPuzzle.generate(spec: PuzzleSpec(difficulty: .puppy), seed: 9)
        let s = QueensSession(puzzle: p)
        s.cycle(0) // -> marked
        s.undo()
        XCTAssertEqual(s.state(at: 0), .empty)
    }
}
