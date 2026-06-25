import Foundation

// MARK: - NoteDetailRoutable（笔记详情模块的"招牌"）
//
// 【这是什么？】
//   这个协议就是笔记详情模块对外挂的"招牌"。
//   调用方认识这块招牌，就能跳转到笔记详情页。
//   协议本身是空的——它只是一个"标识符"，不需要定义任何方法。
//
// 【在哪定义？】
//   定义在笔记详情模块自己的文件里。
//   其他模块要跳转进来，只需要 import 这个文件，不需要 import NoteDetailViewController。
//
// 【和枚举方式的区别？】
//   枚举方式：所有人共用一个 Route.swift，A 跳 B 要改共享文件
//   协议方式：B 自己挂招牌，A 只需要认识招牌，不需要改任何共享文件

protocol NoteDetailRoutable {}

// MARK: - NoteDetailContext（跳转时携带的数据包）
//
// 【为什么用 class 不用 struct？】
//   class 是引用类型，在闭包里修改它的属性，外部能看到变化。
//   调用方会在闭包里往 context 里塞数据，必须用 class。
//
// 【为什么继承 RouteContext？】
//   AppRouter 内部用 RouteContext 类型统一存储，
//   具体的 Context 子类携带各自的业务数据。

class NoteDetailContext: RouteContext {
    var note: Note?   // 要展示哪条笔记
}
