import Foundation

/// v3.2 — Ported from Cosmica. One game listed in the "More from After Hours
/// Dev Studio" shelf.
///
/// The authoritative catalog lives at
/// https://compo-cf.github.io/cosmica/studio-games.json (shared with every app
/// in the portfolio; each app's `StudioShelfProvider` filters out its own
/// `selfID`). A bundled copy ships in `Resources/studio-games.json` so the
/// first launch (and any launch without network) still has data.
///
/// Every optional field uses `decodeIfPresent` so adding new fields on the
/// server never breaks older binaries.
struct StudioGame: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let appStoreID: String
    let name: String
    let tagline: String
    let iconURL: URL
    var sortWeight: Int?
    var audienceTags: [String]?
    var hiddenFromApps: [String]?
    var featuredUntil: Date?

    enum CodingKeys: String, CodingKey {
        case id, appStoreID, name, tagline, iconURL
        case sortWeight, audienceTags, hiddenFromApps, featuredUntil
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id             = try c.decode(String.self, forKey: .id)
        appStoreID     = try c.decode(String.self, forKey: .appStoreID)
        name           = try c.decode(String.self, forKey: .name)
        tagline        = try c.decode(String.self, forKey: .tagline)
        iconURL        = try c.decode(URL.self,    forKey: .iconURL)
        sortWeight     = try c.decodeIfPresent(Int.self,       forKey: .sortWeight)
        audienceTags   = try c.decodeIfPresent([String].self,  forKey: .audienceTags)
        hiddenFromApps = try c.decodeIfPresent([String].self,  forKey: .hiddenFromApps)
        featuredUntil  = try c.decodeIfPresent(Date.self,      forKey: .featuredUntil)
    }

    init(id: String, appStoreID: String, name: String, tagline: String, iconURL: URL,
         sortWeight: Int? = nil, audienceTags: [String]? = nil,
         hiddenFromApps: [String]? = nil, featuredUntil: Date? = nil) {
        self.id = id
        self.appStoreID = appStoreID
        self.name = name
        self.tagline = tagline
        self.iconURL = iconURL
        self.sortWeight = sortWeight
        self.audienceTags = audienceTags
        self.hiddenFromApps = hiddenFromApps
        self.featuredUntil = featuredUntil
    }
}

struct StudioCatalog: Codable, Sendable {
    let version: Int
    let updated: String?
    let games: [StudioGame]
}
