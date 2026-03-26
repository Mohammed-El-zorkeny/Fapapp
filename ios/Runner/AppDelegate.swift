import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var blurView: UIVisualEffectView?

    override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // ✅ Google Maps API Key
        GMSServices.provideAPIKey("AIzaSyA8NdDD7cUCWx_OIvDi0A8EApwA2Bll_sg")

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func applicationWillResignActive(_ application: UIApplication) {
        addBlurEffect()
    }

    override func applicationDidEnterBackground(_ application: UIApplication) {
        addBlurEffect()
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        removeBlurEffect()
    }

    private func addBlurEffect() {
        guard let window = UIApplication.shared.windows.first else { return }

        if window.viewWithTag(999) != nil { return }

        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = window.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.tag = 999

        window.addSubview(blurView)
        self.blurView = blurView
    }

    private func removeBlurEffect() {
        guard let window = UIApplication.shared.windows.first else { return }

        window.viewWithTag(999)?.removeFromSuperview()
        blurView = nil
    }
}
