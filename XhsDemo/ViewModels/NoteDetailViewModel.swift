import Foundation
import Combine

final class NoteDetailViewModel {

    // MARK: - 数据
    let note: Note

    // MARK: - 状态
    @Published private(set) var isLiked: Bool = false
    @Published private(set) var isCollected: Bool = false
    @Published private(set) var isFollowing: Bool = false

    // MARK: - 初始化
    init(note: Note) {
        self.note = note
    }

    // MARK: - 输入
    func toggleLike() {
        isLiked.toggle()
        print("点赞状态：\(isLiked ? "已点赞" : "未点赞")")
    }

    func toggleCollect() {
        isCollected.toggle()
        print("收藏状态：\(isCollected ? "已收藏" : "未收藏")")
    }

    func followAuthor() {
        guard !isFollowing else { return }
        isFollowing = true
        print("已关注：\(note.author)")
    }

    // MARK: - 计算属性
    var displayImageURL: URL? {
        let urlString = note.coverLargeURL ?? note.coverURL
        return urlString.flatMap { URL(string: $0) }
    }
}
