import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {

    private var blurView: UIVisualEffectView?
    private let secureViewTag = 9999
    private let blurViewTag = 1000
    private var secureField: UITextField?

    override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        GMSServices.provideAPIKey("AIzaSyA8NdDD7cUCWx_OIvDi0A8EApwA2Bll_sg")
        GeneratedPluginRegistrant.register(with: self)

        // تفعيل حماية منع التصوير (الطبقة المؤمنة)
        DispatchQueue.main.async {
            self.enableScreenshotProtection(true)
        }

        // مراقبة لقطة الشاشة
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidTakeScreenshot),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )

        // مراقبة تسجيل الشاشة
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenCaptureChanged),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func applicationWillResignActive(_ application: UIApplication) {
        addBlurEffect()
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        removeBlurEffect()
        screenCaptureChanged()
    }

    // MARK: - Screenshot Prevention (الخدعة التقنية لطبقة الصور)
    private func enableScreenshotProtection(_ enable: Bool) {
        DispatchQueue.main.async {
            guard let window = self.getKeyWindow() else { return }
            if enable {
                if self.secureField == nil {
                    let field = UITextField()
                    field.isSecureTextEntry = true
                    field.isUserInteractionEnabled = false
                    window.addSubview(field)
                    window.layer.superlayer?.addSublayer(field.layer)
                    field.layer.sublayers?.first?.addSublayer(window.layer)
                    self.secureField = field
                }
            } else {
                self.secureField?.removeFromSuperview()
                self.secureField = nil
            }
        }
    }

    // ✅ التعديل الجديد: حجب الشاشة عند التقاط لقطة شاشة
    @objc func userDidTakeScreenshot() {
        DispatchQueue.main.async {
            self.blockScreen()
            // إظهار الشاشة السوداء لمدة 3 ثوانٍ كتنبيه رادع
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if !UIScreen.main.isCaptured {
                    self.unblockScreen()
                }
            }
        }
    }

    @objc func screenCaptureChanged() {
        DispatchQueue.main.async {
            if UIScreen.main.isCaptured {
                self.blockScreen()
            } else {
                self.unblockScreen()
            }
        }
    }

    private func blockScreen() {
        guard let window = getKeyWindow() else { return }
        if window.viewWithTag(secureViewTag) != nil { return }

        let secureView = UIView(frame: window.bounds)
        secureView.backgroundColor = .black
        secureView.tag = secureViewTag

        let label = UILabel()
        label.text = "المحتوى محمي\nلا يمكن التصوير أو التسجيل"
        label.numberOfLines = 0
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.frame = secureView.bounds

        secureView.addSubview(label)
        window.addSubview(secureView)
        window.bringSubviewToFront(secureView)
    }

    private func unblockScreen() {
        guard let window = getKeyWindow() else { return }
        window.viewWithTag(secureViewTag)?.removeFromSuperview()
    }

    private func addBlurEffect() {
        guard let window = getKeyWindow() else { return }
        if window.viewWithTag(blurViewTag) != nil { return }
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = window.bounds
        blurView.tag = blurViewTag
        window.addSubview(blurView)
    }

    private func removeBlurEffect() {
        guard let window = getKeyWindow() else { return }
        window.viewWithTag(blurViewTag)?.removeFromSuperview()
    }

    private func getKeyWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first
    }
}