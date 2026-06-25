import Foundation

// MARK: - LiveRoomRoutable（直播间模块的"招牌"）
//
// 和 NoteDetailRoutable 完全对称：
//   - LiveRoomRoutable 协议：标识"我能处理直播间跳转"
//   - LiveRoomContext：携带 room 数据的数据包

protocol LiveRoomRoutable {}

// MARK: - LiveRoomContext（直播间跳转携带的数据包）

class LiveRoomContext: RouteContext {
    var room: LiveRoom?   // 要进入哪个直播间
}
