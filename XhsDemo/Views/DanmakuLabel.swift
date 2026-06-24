import UIKit

// 可复用的弹幕单元
// 从复用池取出后调用 configure(with:) 重新配置，不重新创建对象
final class DanmakuLabel: UILabel {

    private(set) var danmaku: Danmaku?

    override init(frame: CGRect) {
        super.init(frame: frame)
        font = .systemFont(ofSize: 15, weight: .medium)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.6
        layer.shadowOffset = CGSize(width: 1, height: 1)
        layer.shadowRadius = 2
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with danmaku: Danmaku) {
        self.danmaku = danmaku
        text         = danmaku.text
        textColor    = danmaku.color
        sizeToFit()
    }

    func prepareForReuse() {
        danmaku = nil
        text    = nil
    }
}
