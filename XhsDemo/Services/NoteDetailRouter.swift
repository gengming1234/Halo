import UIKit

// MARK: - NoteDetailRouter
//
// 遵守 ProtocolRoutable，实现三个能力：
//   1. makeContext()        → 创建一个 NoteDetailContext 空数据包
//   2. makeViewController() → 从数据包取出 note，创建 NoteDetailViewController
//   3. performNavigation()  → 用 push 进入（笔记详情是层级页面）

struct NoteDetailRouter: ProtocolRoutable {

    // 能力1：创建空数据包
    // 调用方拿到这个空包，在 configure 闭包里往里塞 note 数据
    static func makeContext() -> RouteContext {
        return NoteDetailContext()
    }

    // 能力2：从数据包里取出 note，创建 ViewController
    static func makeViewController(from context: RouteContext) -> UIViewController? {
        // 把基类 RouteContext 向下转型为具体的 NoteDetailContext
        guard let ctx = context as? NoteDetailContext,
              let note = ctx.note   // 确保调用方有填 note 数据
        else { return nil }

        let viewModel = NoteDetailViewModel(note: note)
        return NoteDetailViewController(viewModel: viewModel)
    }

    // 能力3：笔记详情用 push（它是发现列表的下一层）
    static func performNavigation(to destination: UIViewController, from source: UIViewController) {
        source.navigationItem.backButtonTitle = ""
        source.navigationController?.pushViewController(destination, animated: true)
    }
}
