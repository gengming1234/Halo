import UIKit

// MARK: - RouteContext（数据包基类）
//
// 所有具体的 Context（NoteDetailContext、LiveRoomContext）都继承它。
// AppRouter 内部用这个基类统一存储，不需要知道具体是哪种 Context。
// 用 class 而不是 struct，因为闭包里需要修改它的属性（引用类型才能做到）。

class RouteContext {}

// MARK: - ProtocolRoutable（每个具体 Router 必须遵守的协议）
//
// 这个协议规定了每个 Router 必须具备的三个能力：
//   makeContext()          → 创建一个空的数据包（Context）
//   makeViewController()  → 用数据包里的数据创建 ViewController
//   performNavigation()   → 执行跳转动作（push 或 present）
//
// 【为什么把导航方式也放在 Router 里？】
//   不同页面的导航方式不同：笔记详情用 push，直播间用 present。
//   这个逻辑属于"这个页面怎么进入"，应该由对应的 Router 自己决定，
//   而不是由 AppRouter 通过 switch 来判断（那样 AppRouter 又要认识具体页面了）。

protocol ProtocolRoutable {
    /// 创建一个空数据包，等待调用方往里填数据
    static func makeContext() -> RouteContext

    /// 从数据包里取出数据，创建对应的 ViewController
    static func makeViewController(from context: RouteContext) -> UIViewController?

    /// 执行最终的跳转（push 或 present）
    static func performNavigation(to destination: UIViewController, from source: UIViewController)
}

// MARK: - AppRouter（路由中心）
//
// 【注册表的结构】：
//   key   = 协议的名字（字符串）
//           比如 NoteDetailRoutable → "NoteDetailRoutable"
//           用字符串而不是协议本身，因为 Swift 里协议不能直接作为字典的 key
//   value = 能处理这个协议的 Router 类型（ProtocolRoutable.Type）
//
// 【整体流程】：
//   注册：协议名字符串 → Router 类型，存进 routerMap
//   跳转：根据协议名字符串找到 Router → makeContext → 调用方填数据 → makeVC → navigate

final class AppRouter {

    static let shared = AppRouter()
    private init() {}

    // 注册表：协议名（字符串） → 能处理它的 Router 类型
    private var routerMap: [String: ProtocolRoutable.Type] = [:]

    // MARK: - 注册

    /// 注册一个路由
    /// - Parameters:
    ///   - protocolType: 模块暴露的招牌协议（比如 NoteDetailRoutable.self）
    ///   - router:       能处理这个协议的 Router（比如 NoteDetailRouter.self）
    func register<T>(_ protocolType: T.Type, router: ProtocolRoutable.Type) {
        // 把协议类型转成字符串当 key，这是 Swift 里用协议做字典 key 的标准做法
        let key = String(describing: T.self)
        routerMap[key] = router
    }

    // MARK: - 跳转入口

    /// 发起跳转
    /// - Parameters:
    ///   - protocolType: 目标模块的招牌协议（比如 NoteDetailRoutable.self）
    ///   - sourceVC:     发起跳转的 ViewController
    ///   - configure:    填数据的闭包（往 context 里塞参数）
    func navigate<T>(
        to protocolType: T.Type,
        from sourceVC: UIViewController,
        configure: ((RouteContext) -> Void)? = nil
    ) {
        // 第一步：用协议名字符串查注册表
        let key = String(describing: T.self)
        guard let router = routerMap[key] else {
            print("[AppRouter] ⚠️ 未找到协议 '\(key)' 对应的 Router，请检查是否已注册。")
            return
        }

        // 第二步：让 Router 创建一个空数据包
        let context = router.makeContext()

        // 第三步：调用方在闭包里往数据包里塞数据
        configure?(context)

        // 第四步：让 Router 用数据包创建 ViewController
        guard let destination = router.makeViewController(from: context) else {
            print("[AppRouter] ⚠️ Router '\(router)' 创建 ViewController 失败，请检查 Context 数据是否完整。")
            return
        }

        // 第五步：让 Router 执行跳转（push 还是 present，由 Router 自己决定）
        router.performNavigation(to: destination, from: sourceVC)
    }
}
