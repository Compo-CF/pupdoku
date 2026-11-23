import Foundation

/// A free, time-limited Daily Puzzle challenge (the App Store In-App Event
/// "New Year Pup Challenge"). While the window is open, every Daily Puzzle the
/// player solves counts once toward the goal; reaching the goal unlocks a board
/// theme + puppy costume (owned forever) and a Bones bonus. No purchase needed.
///
/// Windows use UTC epoch days, the same clock the Daily Puzzle uses, so the
/// challenge opens and closes with the Daily board for everyone.
struct EventChallenge: Identifiable, Equatable {
    let id: String
    let name: String
    let emoji: String
    let startEpochDay: Int        // first UTC day that counts (inclusive)
    let endEpochDay: Int          // first UTC day that no longer counts (exclusive)
    let goal: Int                 // Dailies needed
    let rewardThemeId: String
    let rewardCostumeId: String
    let rewardBones: Int
    let deepLinkHost: String      // pupdoku://event/<deepLinkHost>
    let dateLabel: String
    let shortLabel: String        // lock label on the theme card, e.g. "Jan Challenge"
    let costumeLabel: String      // e.g. "party-hat puppies"
    let blurb: String             // opening line of the challenge sheet

    func isActive(today: Int) -> Bool { today >= startEpochDay && today < endEpochDay }
    func isUpcoming(today: Int) -> Bool { today < startEpochDay }
    func daysLeft(today: Int) -> Int { max(0, endEpochDay - max(today, startEpochDay)) }
}

enum EventChallengeCatalog {
    /// Jan 4 2027 (epoch day 20822) through Jan 31 2027 (end-exclusive 20850),
    /// right after the Winter Pass Holiday Event (Dec 12 - Jan 3).
    static let newYear2027 = EventChallenge(
        id: "challenge.newyear2027",
        name: "New Year Pup Challenge",
        emoji: "🎉",
        startEpochDay: 20822,
        endEpochDay: 20850,
        goal: 10,
        rewardThemeId: "confetti",
        rewardCostumeId: "newyear",
        rewardBones: 300,
        deepLinkHost: "newyear",
        dateLabel: "Jan 4 - Jan 31",
        shortLabel: "Jan Challenge",
        costumeLabel: "party-hat puppies",
        blurb: "Ring in the new year with the pack.")

    /// Feb 1 2027 (epoch day 20850) through Feb 28 2027 (end-exclusive 20878),
    /// starting the day the New Year Pup Challenge ends.
    static let puppyLove2027 = EventChallenge(
        id: "challenge.puppylove2027",
        name: "Puppy Love Challenge",
        emoji: "💕",
        startEpochDay: 20850,
        endEpochDay: 20878,
        goal: 10,
        rewardThemeId: "puppylove",
        rewardCostumeId: "valentine",
        rewardBones: 300,
        deepLinkHost: "puppylove",
        dateLabel: "Feb 1 - Feb 28",
        shortLabel: "Feb Challenge",
        costumeLabel: "heart-headband puppies",
        blurb: "Share the love with the pack this February.")

    static let all: [EventChallenge] = [newYear2027, puppyLove2027]

    static func challenge(_ id: String) -> EventChallenge? { all.first { $0.id == id } }
    /// The challenge to feature on Home today: the open one, else the next upcoming.
    static func featured(today: Int) -> EventChallenge? {
        all.first { $0.isActive(today: today) } ?? all.first { $0.isUpcoming(today: today) }
    }
}
