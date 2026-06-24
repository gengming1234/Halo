import UIKit

// MARK: - DanmakuView（弹幕渲染层）
//
// 核心机制：
//   1. CADisplayLink 每帧驱动所有弹幕向左移动（替代 UIView.animate 的理由：可暂停、可控速、内存稳定）
//   2. View 复用池：弹幕飞出屏幕后回收复用，不频繁创建销毁 UILabel
//   3. 轨道系统：6 条轨道，防止弹幕上下重叠
//   4. 碰撞检测：新弹幕只进入尾部已离开右边缘的轨道

final class DanmakuView: UIView {

    // MARK: - 轨道配置
    private let trackCount  = 6
    private let trackHeight: CGFloat = 36

    // 每条轨道上，当前最右侧弹幕的"尾部 x 坐标"
    // 用于判断新弹幕进来时该选哪条轨道
    private var trackTailX: [CGFloat] = []

    // MARK: - 复用池
    private var reusePool:     [DanmakuLabel] = []   // 回收区
    private var activeDanmakus: [DanmakuLabel] = []  // 屏幕上飞行中的弹幕

    // MARK: - CADisplayLink
    private var displayLink: CADisplayLink?

    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 布局完成后初始化轨道（需要知道 bounds.height）
        if trackTailX.isEmpty {
            trackTailX = Array(repeating: 0, count: trackCount)
        }
    }

    // MARK: - 公开接口

    func startDisplayLink() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    /// 外部（ViewController）调用此方法添加一条弹幕
    func addDanmaku(_ danmaku: Danmaku) {
        guard let trackIndex = availableTrack() else { return }  // 所有轨道都堵了，丢弃这条弹幕

        let label = dequeue()
        label.configure(with: danmaku)

        // 弹幕初始位置：屏幕右边缘外
        let trackY = trackOriginY(for: trackIndex)
        label.frame = CGRect(
            x: bounds.width,
            y: trackY,
            width: label.frame.width,
            height: trackHeight
        )

        addSubview(label)
        activeDanmakus.append(label)

        // 记录这条轨道新的尾部坐标（弹幕初始在屏幕外，尾部 = 屏幕宽 + 弹幕宽）
        trackTailX[trackIndex] = bounds.width + label.frame.width
    }

    // MARK: - CADisplayLink 回调（每帧执行）
    @objc private func tick() {
        var toRecycle: [DanmakuLabel] = []

        for label in activeDanmakus {
            // 每帧向左移动
            label.frame.origin.x -= label.danmaku?.speed ?? 3.0

            // 飞出屏幕左边缘 → 回收
            if label.frame.maxX < 0 {
                toRecycle.append(label)
            }
        }

        toRecycle.forEach { recycle($0) }

        // 同步更新轨道尾部 x（每帧所有弹幕都在移动，尾部也在跟着移动）
        updateTrackTailX()
    }

    // MARK: - 私有：轨道管理

    /// 找一条可用轨道（尾部已离开右边缘 30pt 以上）
    private func availableTrack() -> Int? {
        let threshold = bounds.width - 30
        // 优先选尾部最靠左的轨道（等待最久的轨道）
        let candidates = trackTailX.enumerated().filter { $0.element < threshold }
        return candidates.min(by: { $0.element < $1.element })?.offset
    }

    /// 计算第 index 条轨道的顶部 Y 坐标
    /// 弹幕分布在视图的中间区域，避开顶部和底部
    private func trackOriginY(for index: Int) -> CGFloat {
        let totalHeight = CGFloat(trackCount) * trackHeight
        let startY = (bounds.height - totalHeight) / 2
        return startY + CGFloat(index) * trackHeight
    }

    /// 每帧更新轨道尾部 x（因为弹幕在移动，尾部 x 也在减小）
    private func updateTrackTailX() {
        // 对每条轨道，找该轨道上 x 最大的 label
        var newTailX = Array(repeating: CGFloat(0), count: trackCount)

        for label in activeDanmakus {
            let trackIndex = trackIndexFor(label: label)
            if trackIndex >= 0 && trackIndex < trackCount {
                newTailX[trackIndex] = max(newTailX[trackIndex], label.frame.maxX)
            }
        }
        trackTailX = newTailX
    }

    /// 根据 label 的 y 坐标反推它在哪条轨道
    private func trackIndexFor(label: DanmakuLabel) -> Int {
        let totalHeight = CGFloat(trackCount) * trackHeight
        let startY = (bounds.height - totalHeight) / 2
        return max(0, Int((label.frame.origin.y - startY) / trackHeight))
    }

    // MARK: - 私有：复用池管理

    private func dequeue() -> DanmakuLabel {
        if let recycled = reusePool.popLast() {
            return recycled
        }
        return DanmakuLabel()
    }

    private func recycle(_ label: DanmakuLabel) {
        activeDanmakus.removeAll { $0 === label }
        label.prepareForReuse()
        label.removeFromSuperview()
        reusePool.append(label)
    }
}
