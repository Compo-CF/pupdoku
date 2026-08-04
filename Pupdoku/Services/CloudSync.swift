import Foundation
import CloudKit

/// Cross-device save sync via the CloudKit private DB. One record per user
/// (`recordName == "primary"`); payload is the JSON-encoded `GameState` plus a
/// denormalized `progressScore` for cheap conflict resolution.
actor CloudSync {
    private let container: CKContainer
    private let recordType = "PupdokuState"
    private let recordId = CKRecord.ID(recordName: "primary")

    init(container: CKContainer = .default()) {
        self.container = container
    }

    private var privateDB: CKDatabase { container.privateCloudDatabase }

    /// A monotonic-ish measure of progress used to pick a winner when local and
    /// remote diverge. Total wins dominate; play time breaks ties.
    private func progressScore(_ s: GameState) -> Double {
        Double(s.totalWins) * 1_000_000 + s.totalPlaySeconds
    }

    func push(state: GameState) async throws {
        let data = try JSONEncoder().encode(state)
        let record: CKRecord
        do {
            record = try await privateDB.record(for: recordId)
        } catch let error as CKError where error.code == .unknownItem {
            record = CKRecord(recordType: recordType, recordID: recordId)
        }
        record["state"] = data as CKRecordValue
        record["progressScore"] = progressScore(state) as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        _ = try await privateDB.save(record)
    }

    func pull() async throws -> GameState? {
        do {
            let rec = try await privateDB.record(for: recordId)
            guard let data = rec["state"] as? Data else { return nil }
            return try JSONDecoder().decode(GameState.self, from: data)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    /// Higher progress wins. Simple and cheating-resistant enough for a
    /// non-competitive single-player save.
    func reconcile(local: GameState, remote: GameState) -> GameState {
        progressScore(remote) > progressScore(local) ? remote : local
    }
}
