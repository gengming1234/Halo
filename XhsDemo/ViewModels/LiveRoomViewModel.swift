import Foundation
import Combine

final class LiveRoomViewModel {

    let room: LiveRoom

    // MARK: - 输出（View 订阅）
    @Published private(set) var danmaku: Danmaku?       // 每次新弹幕到达发一个
    @Published private(set) var viewerCount: Int        // 实时在线人数

    // MARK: - 内部状态
    private var cancellables = Set<AnyCancellable>()
    private var danmakuTimer: AnyCancellable?
    private var viewerTimer: AnyCancellable?

    init(room: LiveRoom) {
        self.room = room
        self.viewerCount = room.viewerCount
    }

    // MARK: - 输入
    func startStream() {
        // 每 0.8s 随机发一条弹幕
        danmakuTimer = Timer.publish(every: 0.8, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.danmaku = Danmaku.random()
            }

        // 每 3s 随机波动观看人数（±50~300）
        viewerTimer = Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                let delta = Int.random(in: -50...300)
                self.viewerCount = max(0, self.viewerCount + delta)
            }
    }

    func stopStream() {
        danmakuTimer?.cancel()
        viewerTimer?.cancel()
    }
}
