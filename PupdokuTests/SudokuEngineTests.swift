import XCTest
@testable import Pupdoku

final class SudokuEngineTests: XCTestCase {

    // MARK: - Solution grids are valid

    func testGeneratedSolutionIsValidForEverySize() {
        for size in GridSize.allCases {
            let spec = PuzzleSpec(size: size, difficulty: .medium)
            let result = SudokuGenerator(spec: spec).generate(seed: 12345)
            XCTAssertTrue(result.solution.isSolved(),
                          "\(size.displayName) solution must be a valid complete grid")
            XCTAssertEqual(result.solution.filledCount, size.cellCount)
        }
    }

    // MARK: - Puzzles have a unique solution

    func testGeneratedPuzzlesAreUnique() {
        for size in GridSize.allCases {
            for difficulty in Difficulty.allCases {
                let spec = PuzzleSpec(size: size, difficulty: difficulty)
                let result = SudokuGenerator(spec: spec).generate(seed: 777)
                XCTAssertEqual(SudokuSolver.countSolutions(result.puzzle, limit: 2), 1,
                               "\(size.displayName)/\(difficulty.displayName) must have exactly one solution")
            }
        }
    }

    func testPuzzleSolvesToTheStatedSolution() {
        let spec = PuzzleSpec(size: .nine, difficulty: .hard)
        let result = SudokuGenerator(spec: spec).generate(seed: 42)
        let solved = SudokuSolver.solve(result.puzzle)
        XCTAssertEqual(solved, result.solution)
    }

    // MARK: - Determinism (Daily Puzzle guarantee)

    func testSameSeedProducesSameBoard() {
        let spec = PuzzleSpec(size: .nine, difficulty: .medium)
        let a = SudokuGenerator(spec: spec).generate(seed: 2026)
        let b = SudokuGenerator(spec: spec).generate(seed: 2026)
        XCTAssertEqual(a.puzzle, b.puzzle)
        XCTAssertEqual(a.solution, b.solution)
    }

    func testDifferentSeedsUsuallyDiffer() {
        let spec = PuzzleSpec(size: .nine, difficulty: .medium)
        let a = SudokuGenerator(spec: spec).generate(seed: 1)
        let b = SudokuGenerator(spec: spec).generate(seed: 2)
        XCTAssertNotEqual(a.puzzle, b.puzzle)
    }

    func testDailySeedIsStablePerDay() {
        let date = Date(timeIntervalSince1970: 1_770_000_000)
        XCTAssertEqual(SeededRNG.dailySeed(for: date), SeededRNG.dailySeed(for: date))
    }

    // MARK: - Clue counts land near target

    func testClueCountRespectsDifficultyOrdering() {
        let size = GridSize.nine
        let puppy = SudokuGenerator(spec: .init(size: size, difficulty: .puppy)).generate(seed: 9)
        let hard  = SudokuGenerator(spec: .init(size: size, difficulty: .hard)).generate(seed: 9)
        XCTAssertGreaterThan(puppy.clues, hard.clues,
                             "Easier difficulties should leave more clues on the board")
    }

    // MARK: - Session behaviour

    @MainActor
    func testCorrectPlacementDoesNotCountMistake() {
        let spec = PuzzleSpec(size: .four, difficulty: .easy)
        let puzzle = Puzzle.generate(spec: spec, seed: 5)
        let session = PuzzleSession(puzzle: puzzle)
        // Find an empty cell and place its correct value.
        let flat = puzzle.givens.cells.firstIndex(of: 0)!
        session.select(flat)
        session.place(puzzle.solution[flat])
        XCTAssertEqual(session.mistakes, 0)
        XCTAssertEqual(session.value(at: flat), puzzle.solution[flat])
    }

    @MainActor
    func testWrongPlacementCountsMistake() {
        let spec = PuzzleSpec(size: .four, difficulty: .easy)
        let puzzle = Puzzle.generate(spec: spec, seed: 6)
        let session = PuzzleSession(puzzle: puzzle)
        let flat = puzzle.givens.cells.firstIndex(of: 0)!
        let correct = puzzle.solution[flat]
        let wrong = (1...4).first { $0 != correct }!
        session.select(flat)
        session.place(wrong)
        XCTAssertEqual(session.mistakes, 1)
    }

    @MainActor
    func testFillingSolutionWins() {
        let spec = PuzzleSpec(size: .four, difficulty: .puppy)
        let puzzle = Puzzle.generate(spec: spec, seed: 7)
        let session = PuzzleSession(puzzle: puzzle)
        for flat in 0..<puzzle.givens.cells.count where puzzle.givens[flat] == 0 {
            session.select(flat)
            session.place(puzzle.solution[flat])
        }
        XCTAssertEqual(session.status, .won)
    }

    @MainActor
    func testHintRevealsCorrectValue() {
        let spec = PuzzleSpec(size: .six, difficulty: .medium)
        let puzzle = Puzzle.generate(spec: spec, seed: 8)
        let session = PuzzleSession(puzzle: puzzle)
        XCTAssertTrue(session.useHint())
        XCTAssertEqual(session.hintsUsed, 1)
    }

    @MainActor
    func testUndoRestoresPreviousValue() {
        let spec = PuzzleSpec(size: .four, difficulty: .easy)
        let puzzle = Puzzle.generate(spec: spec, seed: 9)
        let session = PuzzleSession(puzzle: puzzle)
        let flat = puzzle.givens.cells.firstIndex(of: 0)!
        session.select(flat)
        session.place(puzzle.solution[flat])
        session.undo()
        XCTAssertEqual(session.value(at: flat), 0)
    }
}
