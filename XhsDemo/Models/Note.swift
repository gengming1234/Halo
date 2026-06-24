import Foundation

// MARK: - Note（UI 展示模型）
//
// 【它在 MVVM 里的角色】：Model 层
//
// 【设计原则】：
//   - 只有字段，没有任何方法和逻辑
//   - 字段全部是"已处理好"的，View 拿到直接用，不需要再做任何加工
//   - 比如 timeText 已经是 "3小时前"，View 直接显示，不需要知道时间戳
//
// 【和 NoteDTO 的区别】：
//   - NoteDTO 是"从网络/JSON来的原始脏数据"，字段可能是 nil，格式是后端定的
//   - Note 是"给 View 用的干净数据"，字段都有默认值，格式是 UI 需要的
//   - 从 NoteDTO → Note 的转换工作，由 NoteService 来做

struct Note {
    let title: String           // 已截断处理好的标题，View 直接用
    let author: String          // 作者昵称，已有默认值 "unknown"
    let content: String         // 正文内容，已有默认值 "（无正文）"
    let timeText: String        // 格式化好的相对时间，如 "3小时前"
    let coverURL: String?       // 列表封面图 URL（可能没有图）
    let coverLargeURL: String?  // 详情大图 URL（可能没有图）
}
