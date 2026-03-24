import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var blurView: UIVisualEffectView?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Hide content when app goes to background (prevents screenshot in app switcher)
  override func applicationWillResignActive(_ application: UIApplication) {
    addBlurEffect()
  }
  
  override func applicationDidBecomeActive(_ application: UIApplication) {
    removeBlurEffect()
  }
  
  private func addBlurEffect() {
    guard let window = self.window else { return }
    
    let blurEffect = UIBlurEffect(style: .dark)
    let blurView = UIVisualEffectView(effect: blurEffect)
    blurView.frame = window.bounds
    blurView.tag = 999 // Tag to identify later
    
    window.addSubview(blurView)
    self.blurView = blurView
  }
  
  private func removeBlurEffect() {
    blurView?.removeFromSuperview()
    blurView = nil
  }
}
