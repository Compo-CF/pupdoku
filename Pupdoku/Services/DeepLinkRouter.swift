import SwiftUI

/// Routes incoming deep links (notably App Store In-App Event links) to an
/// in-app destination.
///
/// The app registers the `pupdoku://` URL scheme (see `project.yml` →
/// `CFBundleURLTypes`). `PupdokuApp`'s `.onOpenURL` feeds links here, and
/// `HomeView` observes `pendingRoute` to present the matching screen.
///
/// Example: the Winter Pass event uses `pupdoku://event/winter`, which opens the
/// Shop (where the Winter Pass and cosmetics live). Unknown links still bring the
/// app to the foreground without error.
@Observable
final class DeepLinkRouter {
    enum Route: Equatable {
        /// Open the Shop (passes, Bones, and cosmetics).
        case shop
    }

    /// Set when a deep link arrives; a view consumes it and resets it to nil.
    var pendingRoute: Route?

    /// Parse a `pupdoku://…` URL into a route. Non-matching links are ignored.
    func handle(_ url: URL) {
        guard url.scheme?.lowercased() == "pupdoku" else { return }
        switch url.host?.lowercased() {
        case "event", "shop", "winter":
            pendingRoute = .shop
        default:
            // Any other pupdoku:// link just foregrounds the app.
            break
        }
    }
}
