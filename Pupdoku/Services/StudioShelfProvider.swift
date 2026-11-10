import Foundation
import Observation

/// v3.2 — Ported from Cosmica. Holds the "More from After Hours Dev Studio"
/// catalog for Pupdoku.
///
/// Flow on launch: seed `games` instantly from the on-disk cache (or the
/// bundled fallback), then kick off a background `refresh()` that pulls the
/// latest JSON from the shared Pages bucket, writes it to disk, and
/// republishes `games`. Foreground triggers a throttled refresh too.
///
/// `selfID` ensures a game whose id matches this app (or that lists this app
/// in `hiddenFromApps`) is filtered out, so one catalog serves every app in
/// the portfolio without showing an app its own card.
@MainActor
@Observable
final class StudioShelfProvider {
    private(set) var games: [StudioGame] = []
    private(set) var isRefreshing = false
    private(set) var lastRefreshed: Date?
    private(set) var lastError: Error?

    let selfID: String
    let catalogURL: URL
    let minRefreshInterval: TimeInterval

    private let session: URLSession
    private let bundle: Bundle
    private let fileManager: FileManager
    private let cacheFileName = "studio-games.json"
    private let bundledResourceName = "studio-games"
    private var rawGames: [StudioGame] = []

    init(selfID: String,
         catalogURL: URL = URL(string: "https://compo-cf.github.io/cosmica/studio-games.json")!,
         minRefreshInterval: TimeInterval = 3_600,
         session: URLSession = .shared,
         bundle: Bundle = .main,
         fileManager: FileManager = .default) {
        self.selfID = selfID
        self.catalogURL = catalogURL
        self.minRefreshInterval = minRefreshInterval
        self.session = session
        self.bundle = bundle
        self.fileManager = fileManager
        if let cached = loadCached() {
            apply(cached)
        } else if let bundled = loadBundled() {
            apply(bundled)
        }
    }

    func refresh(force: Bool = false) async {
        if isRefreshing { return }
        if !force, let last = lastRefreshed,
           Date().timeIntervalSince(last) < minRefreshInterval { return }
        isRefreshing = true
        defer { isRefreshing = false }

        var request = URLRequest(url: catalogURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10
        do {
            let (data, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }
            let catalog = try decode(data)
            apply(catalog)
            saveCache(data)
            lastRefreshed = Date()
            lastError = nil
        } catch {
            lastError = error
        }
    }

    private func apply(_ catalog: StudioCatalog) {
        rawGames = catalog.games
        games = catalog.games
            .filter { $0.id != selfID }
            .filter { !($0.hiddenFromApps?.contains(selfID) ?? false) }
            .sorted { lhs, rhs in
                let l = lhs.sortWeight ?? Int.max
                let r = rhs.sortWeight ?? Int.max
                if l != r { return l < r }
                let li = rawGames.firstIndex(of: lhs) ?? 0
                let ri = rawGames.firstIndex(of: rhs) ?? 0
                return li < ri
            }
    }

    private func decode(_ data: Data) throws -> StudioCatalog {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(StudioCatalog.self, from: data)
    }

    private var cacheURL: URL? {
        guard let dir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        return dir.appendingPathComponent(cacheFileName)
    }

    private func loadCached() -> StudioCatalog? {
        guard let url = cacheURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? decode(data)
    }

    private func saveCache(_ data: Data) {
        guard let url = cacheURL else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func loadBundled() -> StudioCatalog? {
        guard let url = bundle.url(forResource: bundledResourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? decode(data)
    }
}
