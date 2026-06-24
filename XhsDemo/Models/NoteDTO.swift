import Foundation

// MARK: - DTO 层（Data Transfer Object，数据传输对象）
//
// 【它在 MVVM 里的角色】：Model 层（原始数据部分）
//
// 【设计原则】：
//   - 字段结构和 JSON/后端保持一致，字段允许为 nil（因为后端不一定给）
//   - 不做任何格式转换，只负责"把 JSON 解码成 Swift 对象"
//   - 命名遵循后端的 snake_case，通过 CodingKeys 映射到 Swift camelCase
//
// 【谁来用这些 DTO？】：
//   - 只有 NoteService 用，用完之后转换成 Note，ViewController 永远不会碰 DTO

// 最外层 API 响应：{ "code": 0, "data": [...] }
struct ApiResponseDTO: Decodable {
    let code: Int?
    let success: Bool?
    let msg: String?
    let data: [NoteDTO]
}

// 单条笔记原始数据
struct NoteDTO: Decodable {
    let id: String?
    let title: String?
    let desc: String?
    let timestamp: TimeInterval?
    let imagesList: [ImageDTO]?
    let user: UserDTO?

    enum CodingKeys: String, CodingKey {
        case id, title, desc, timestamp, user
        case imagesList = "images_list"   // 后端是 snake_case，这里做映射
    }
}

// 用户信息原始数据
struct UserDTO: Decodable {
    let userid: String?
    let nickname: String?
    let images: String?
}

// 图片原始数据
struct ImageDTO: Decodable {
    let fileid: String
    let url: String?
    let urlSizeLarge: String?

    enum CodingKeys: String, CodingKey {
        case fileid, url
        case urlSizeLarge = "url_size_large"
    }
}
