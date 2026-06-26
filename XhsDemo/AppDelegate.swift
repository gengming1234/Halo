import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 路由注册：告诉 AppRouter 每个"招牌协议"对应哪个 Router
        // 如果不注册，navigate(to:) 查不到 Router，跳转会直接失败并打印警告
        AppRouter.shared.register(NoteDetailRoutable.self, router: NoteDetailRouter.self)
        AppRouter.shared.register(LiveRoomRoutable.self,   router: LiveRoomRouter.self)
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
    }
}
