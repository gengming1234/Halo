import UIKit
import SnapKit
import Kingfisher
import YYKit

// MARK: - NoteCell（笔记列表 Cell）
//
// 【它在 MVVM 里的角色】：View 层
//
// 【职责】：
//   1. 负责"画出来"：图片、标题、作者信息的布局
//   2. 接收 Note 数据，把字段填进对应控件（configure 方法）
//   3. 把"用户点击了某处"这个事件抛出去（onDetailTap 闭包）
//
// 【不能做的事】：
//   ❌ 不能知道 Note 数据从哪里来
//   ❌ 不能做任何业务判断（比如"这个笔记要不要显示"）
//   ❌ 不能持有 ViewController 的引用
//
// 【onDetailTap 为什么用闭包而不是代理？】
//   Cell 是被 CollectionView 管理的，它不知道谁拥有它（可能是任何 VC）。
//   用闭包：Cell 说"我被点了"，由外部（VC）决定点了之后干什么。
//   这样 Cell 就和具体的业务完全解耦，可以在任何地方复用。

final class NoteCell: UICollectionViewCell {

    // MARK: - 复用标识符
    static let reuseID = "NoteCell"

    // MARK: - UI 控件（View 层持有的所有子视图）
    let titleLabel  = YYLabel()
    let detailLabel = YYLabel()
    let coverImageView = UIImageView()

    // MARK: - 布局常量（统一管理，方便修改）
    private let padding: CGFloat = 10
    private let imageToTitleSpacing: CGFloat = 8
    private let titleToDetailSpacing: CGFloat = 6

    // MARK: - 事件回调（View → ViewController 的向上通知）
    //
    // 【使用场景】：用户点击了 detailLabel（作者和时间区域）
    // 【为什么是闭包】：Cell 不知道点了之后该做什么，这个决策权交给 ViewController
    // 【ViewController 怎么用】：
    //   cell.onDetailTap = {
    //       print("用户点击了作者信息")
    //   }
    var onDetailTap: (() -> Void)?

    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAppearance()
        setupSubviews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 配置（接收来自 ViewController 的 Note 数据）
    //
    // 【调用时机】：CollectionView 的 cellForItemAt 里
    // 【参数】：已经处理好的干净数据 Note，直接塞进控件，无需任何判断
    func configure(with note: Note) {
        // 1. 标题
        titleLabel.text = note.title

        // 2. 作者 + 时间（富文本，带点击高亮）
        let detailString = "\(note.author) · \(note.timeText)"
        let attributed = NSMutableAttributedString(string: detailString)
        let fullRange = NSRange(location: 0, length: attributed.length)

        attributed.addAttribute(.font, value: UIFont.systemFont(ofSize: 13), range: fullRange)
        attributed.addAttribute(.foregroundColor, value: UIColor.gray, range: fullRange)

        // 给 YYLabel 设置点击高亮，点击时触发 onDetailTap
        let highlight = YYTextHighlight()
        highlight.tapAction = { [weak self] _, _, _, _ in
            self?.onDetailTap?()
        }
        attributed.addAttribute(
            NSAttributedString.Key(rawValue: YYTextHighlightAttributeName),
            value: highlight,
            range: fullRange
        )
        detailLabel.attributedText = attributed

        // 3. 图片（用 Kingfisher 异步加载）
        let url = note.coverURL.flatMap { URL(string: $0) }
        coverImageView.kf.indicatorType = .activity
        coverImageView.kf.setImage(
            with: url,
            placeholder: UIImage(systemName: "photo"),
            options: [
                .transition(.fade(0.3)),       // 淡入动画
                .backgroundDecode,              // 后台解码，不阻塞主线程
                .retryStrategy(DelayRetryStrategy(maxRetryCount: 3, retryInterval: .seconds(1)))
            ]
        )
    }

    // MARK: - 按压缩放动画（视觉反馈）
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(
                withDuration: 0.2,
                delay: 0,
                options: [.beginFromCurrentState, .allowUserInteraction]
            ) {
                self.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.95, y: 0.95)
                    : .identity
            }
        }
    }
}

// MARK: - 私有：UI 设置（和业务无关的纯视觉逻辑）
private extension NoteCell {

    func setupAppearance() {
        contentView.backgroundColor = .systemGray6
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
    }

    func setupSubviews() {
        // 标题标签
        configureYYLabel(titleLabel, fontSize: 16, weight: .medium, color: .black, lines: 2)
        // 详情标签（作者 + 时间）
        configureYYLabel(detailLabel, fontSize: 13, weight: .regular, color: .gray, lines: 1)

        // 封面图
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.isUserInteractionEnabled = true
        coverImageView.layer.borderWidth = 1
        coverImageView.layer.borderColor = UIColor.systemGray4.cgColor

        contentView.addSubview(coverImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
    }

    func configureYYLabel(_ label: YYLabel,
                           fontSize: CGFloat,
                           weight: UIFont.Weight,
                           color: UIColor,
                           lines: UInt) {
        label.font = .systemFont(ofSize: fontSize, weight: weight)
        label.textColor = color
        label.numberOfLines = lines
        label.lineBreakMode = .byTruncatingTail
        label.textVerticalAlignment = .top
        label.displaysAsynchronously = true  // 异步渲染，提升列表滚动流畅度
    }

    func setupConstraints() {
        coverImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(padding)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.height.equalTo(coverImageView.snp.width).multipliedBy(4.0 / 3.0)  // 3:4 宽高比
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(coverImageView.snp.bottom).offset(imageToTitleSpacing)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        detailLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(titleToDetailSpacing)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.bottom.equalToSuperview().inset(padding)
        }
    }
}
