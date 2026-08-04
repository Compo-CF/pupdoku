import UIKit
import GoogleMobileAds
import AVFoundation

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        MobileAds.shared.start(completionHandler: nil)

        // .ambient: our sounds respect the hardware mute switch and mix politely
        // with any audio the user already has playing.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        return true
    }
}
