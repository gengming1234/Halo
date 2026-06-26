import Foundation

// MARK: - NoteCache（笔记内存缓存）
//
// 【设计参考】：Halo 项目的 SearchResultCacheManager / XYUGLRUCache
//
// 【设计原则】：
//   1. 单一职责：只负责缓存的存/取/清，不关心数据从哪来、用到哪里
//   2. 独立分层：ViewModel 调用它，但它不知道 ViewModel 的存在
//   3. 容量限制：最多缓存 maxCount 个分类，超出由 NSCache 自动 LRU 淘汰
//
// 【和 Halo 的对比】：
//   Halo：YYMemoryCache + YYDiskCache（内存 + 磁盘双层）
//   Demo：NSCache（只有内存层，App 退出清空，当前阶段够用）
//
// 【Key 设计参考 Halo】：
//   Halo：SearchResultCache_{userId}_{base64(keyword)}
//   Demo：notes_category_{index}（无需用户隔离，Demo 无登录功能）

final class NoteCache {

    // MARK: - 单例
    static let shared = NoteCache()
    private init() {
        // NSCache 是线程安全的，不需要额外加锁
        // countLimit：最多缓存 8 个分类（对应 8 个 Tab）
        // 超出限制时 NSCache 自动按 LRU 策略淘汰最久未使用的
        cache.countLimit = 8
        cache.name = "com.xhsdemo.noteCache"
    }

    // MARK: - 存储
    // NSCache：
    //   - 线程安全（Halo 的 SearchResultCacheManager 用 DispatchQueue 手动保证，NSCache 自动处理）
    //   - 内存不足时自动清理（系统级 LRU）
    //   - key/value 必须是 AnyObject，所以用 NSNumber / NSArray 包装
    private let cache = NSCache<NSString, NSArray>()

    // MARK: - 对外接口

    /// 存入缓存
    /// - Parameters:
    ///   - notes: 要缓存的笔记数组
    ///   - categoryIndex: 分类下标（作为 Key）
    func set(_ notes: [Note], forCategory categoryIndex: Int) {
        let key = cacheKey(for: categoryIndex)
        cache.setObject(notes as NSArray, forKey: key)
    }

    /// 读取缓存（命中返回 [Note]，未命中返回 nil）
    /// - Parameter categoryIndex: 分类下标
    func get(forCategory categoryIndex: Int) -> [Note]? {
        let key = cacheKey(for: categoryIndex)
        return cache.object(forKey: key) as? [Note]
    }

    /// 清除指定分类的缓存
    func remove(forCategory categoryIndex: Int) {
        cache.removeObject(forKey: cacheKey(for: categoryIndex))
    }

    /// 清除全部缓存
    /// 参考 Halo 的 XYClearDefaultDiskCaches.clearCache()，提供统一清理入口
    /// 使用场景：退出登录、用户手动清理缓存
    func clearAll() {
        cache.removeAllObjects()
    }

    // MARK: - 私有

    /// Key 设计：参考 Halo 的 "SearchResultCache_{userId}_{keyword}"
    /// Demo 简化为 "notes_category_{index}"
    private func cacheKey(for categoryIndex: Int) -> NSString {
        return "notes_category_\(categoryIndex)" as NSString
    }
}
