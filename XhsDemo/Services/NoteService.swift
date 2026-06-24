import Foundation

// MARK: - NoteService（数据加载服务）
//
// 【它在 MVVM 里的角色】：Service 层（Model 层的一部分）
//
// 【职责】：
//   1. 从文件/网络获取原始数据
//   2. 把 DTO（原始脏数据）转换成 Model（干净数据）
//   3. 把干净数据返回给 ViewModel
//
// 【谁调用它？】：ViewModel 调用（ViewController 不直接调用）
// 【它知道谁？】：只知道 Model 层（Note、NoteDTO），不知道 ViewModel，不知道 View
//
// 【为什么用 enum 而不是 class/struct？】
//   Service 不需要实例（没有属性状态），只是一组工具函数，
//   用 enum 是 Swift 里防止被实例化的惯用写法（等同于 Java 的 abstract class）

enum NoteService {

    // MARK: - 对外暴露的接口（ViewModel 只调这一个方法）

    /// 从 Bundle 内的 JSON 文件加载笔记列表
    /// - Parameter jsonName: JSON 文件名（不含扩展名），如 "xiaohongshu"
    /// - Returns: 转换好的 [Note] 数组，可直接给 View 使用
    /// - Throws: 文件不存在或解码失败时抛出错误
    static func loadNotesFromBundle(jsonName: String) throws -> [Note] {
        // 步骤1：在 App Bundle 里找 JSON 文件
        guard let url = Bundle.main.url(forResource: jsonName, withExtension: "json") else {
            throw NoteServiceError.fileNotFound(jsonName)
        }

        // 步骤2：把文件读成二进制 Data
        let data = try Data(contentsOf: url)

        // 步骤3：JSON 解码 → ApiResponseDTO（原始结构）
        let resp = try JSONDecoder().decode(ApiResponseDTO.self, from: data)

        // 步骤4：DTO → Note（数据清洗 + 格式转换）
        // sorted: 按时间戳倒序（最新的在前）
        // map: 把每个 NoteDTO 转成一个干净的 Note
        return resp.data
            .sorted { ($0.timestamp ?? 0) > ($1.timestamp ?? 0) }
            .map(convertToNote)
    }

    // MARK: - 私有：转换逻辑（DTO → Note）
    //
    // 【为什么这些逻辑放在 Service 而不是 ViewModel？】
    //   这些是"数据清洗"逻辑，跟具体页面的业务无关，
    //   任何页面需要 Note 数据时都需要同样的清洗，所以放 Service 里复用

    private static func convertToNote(_ dto: NoteDTO) -> Note {
        // 标题：优先用 title，没有就用 desc 的第一行
        let rawTitle = (dto.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            ? dto.title : dto.desc

        let firstImage = dto.imagesList?.first
        let content = (dto.desc ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        return Note(
            title: formatTitle(from: rawTitle),
            author: dto.user?.nickname ?? "unknown",
            content: content.isEmpty ? "（无正文）" : content,
            timeText: formatRelativeTime(from: dto.timestamp),
            coverURL: firstImage?.url,
            coverLargeURL: firstImage?.urlSizeLarge
        )
    }

    /// 把长文本截成短标题（取第一行，最多 30 字）
    private static func formatTitle(from raw: String?) -> String {
        let s = (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return "（无内容）" }
        let firstLine = s.components(separatedBy: .newlines).first ?? s
        return String(firstLine.prefix(30))
    }

    /// 把时间戳转成 "3小时前" 这种相对时间字符串
    private static func formatRelativeTime(from ts: TimeInterval?) -> String {
        guard let ts else { return "未知时间" }
        let seconds = Int(Date().timeIntervalSince(Date(timeIntervalSince1970: ts)))
        if seconds < 60  { return "\(seconds)秒前" }
        let minutes = seconds / 60
        if minutes < 60  { return "\(minutes)分钟前" }
        let hours = minutes / 60
        if hours < 24    { return "\(hours)小时前" }
        return "\(hours / 24)天前"
    }
}

// MARK: - 错误类型
//
// 自定义错误让调用方（ViewModel）能区分不同的失败原因
enum NoteServiceError: LocalizedError {
    case fileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name):
            return "找不到 \(name).json 文件，请检查资源是否加入了 Target"
        }
    }
}
