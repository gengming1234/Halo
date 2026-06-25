import UIKit

// MARK: - LiveRoomRouter
//
// 遵守 ProtocolRoutable，实现三个能力：
//   1. makeContext()        → 创建一个 LiveRoomContext 空数据包
//   2. makeViewController() → 从数据包取出 room，创建 LiveRoomViewController
//   3. performNavigation()  → 用 present 进入（直播间是全屏独立场景）

struct LiveRoomRouter: ProtocolRoutable {

    // 能力1：创建空数据包
    static func makeContext() -> RouteContext {
        return LiveRoomContext()
    }

    // 能力2：从数据包里取出 room，创建 ViewController
    static func makeViewController(from context: RouteContext) -> UIViewController? {
        guard let ctx = context as? LiveRoomContext,
              let room = ctx.room
        else { return nil }

        let viewModel = LiveRoomViewModel(room: room)
        return LiveRoomViewController(viewModel: viewModel)
    }

    // 能力3：直播间用 present 全屏弹出（它是独立的沉浸式场景）
    static func performNavigation(to destination: UIViewController, from source: UIViewController) {
        source.present(destination, animated: true)
    }
}
