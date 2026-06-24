import UIKit

struct Danmaku {
    let id: UUID
    let text: String
    let color: UIColor
    let speed: CGFloat   // pt/帧，CADisplayLink 每帧移动量

    init(text: String, color: UIColor = .white, speed: CGFloat = CGFloat.random(in: 2.5...4.5)) {
        self.id    = UUID()
        self.text  = text
        self.color = color
        self.speed = speed
    }

    static let presetTexts: [String] = [
        "好看好看！", "主播加油！", "第一次看直播",
        "666", "哇塞这也太美了", "求同款链接！",
        "冲冲冲！", "路过打个卡", "今天也爱主播❤️",
        "主播声音好好听", "哈哈哈哈", "太厉害了！",
        "在线蹲直播", "求推荐", "同款已下单🛍️",
        "笑死我了", "主播yyds", "感谢分享！",
        "好想去", "羡慕！", "bgm是什么歌",
    ]

    static func random() -> Danmaku {
        let text  = presetTexts.randomElement()!
        let color = [UIColor.white, .systemYellow, .cyan, .systemGreen, .systemPink].randomElement()!
        return Danmaku(text: text, color: color)
    }
}
