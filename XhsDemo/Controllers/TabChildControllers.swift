import UIKit
import SnapKit

// MARK: - TabChildControllers.swift
//
// 存放购物、消息、我的、关注、附近等简单的 Tab 子页面
// 这些页面目前是占位实现，后续可以各自拆成独立文件

// MARK: - 关注页
final class FollowViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(makeCenterLabel("关注页面"))
            .snp.makeConstraints { $0.center.equalToSuperview() }
    }
}

// MARK: - 附近页
final class NearbyViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(makeCenterLabel("附近页面"))
            .snp.makeConstraints { $0.center.equalToSuperview() }
    }
}

// MARK: - 购物页
class ShopViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "购物"
        view.addSubview(makeCenterLabel("🛍️ 购物页面"))
            .snp.makeConstraints { $0.center.equalToSuperview() }
    }
}

// MARK: - 消息页
class MessageViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "消息"
        view.addSubview(makeCenterLabel("💬 消息页面"))
            .snp.makeConstraints { $0.center.equalToSuperview() }
    }
}

// MARK: - 发布页
class PublishViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "发布"
        setupUI()
    }

    private func setupUI() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center

        let options: [(String, String, String, UIColor)] = [
            ("发布笔记", "分享你的生活瞬间", "square.and.pencil", .systemRed),
            ("发布视频", "记录精彩时刻",     "video.fill",        .systemBlue),
            ("开始直播", "与粉丝实时互动",   "dot.radiowaves.left.and.right", .systemPurple)
        ]
        for option in options {
            stackView.addArrangedSubview(makePublishButton(option))
        }

        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
    }

    private func makePublishButton(_ option: (String, String, String, UIColor)) -> UIButton {
        let (title, subtitle, icon, color) = option
        let button = UIButton(type: .system)
        button.backgroundColor = color.withAlphaComponent(0.1)
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = color.withAlphaComponent(0.3).cgColor

        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.spacing = 16
        hStack.alignment = .center
        hStack.isUserInteractionEnabled = false

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = color
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { $0.width.height.equalTo(30) }

        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.alignment = .leading
        vStack.spacing = 4

        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLbl.textColor = color

        let subLbl = UILabel()
        subLbl.text = subtitle
        subLbl.font = .systemFont(ofSize: 14)
        subLbl.textColor = .systemGray

        vStack.addArrangedSubview(titleLbl)
        vStack.addArrangedSubview(subLbl)
        hStack.addArrangedSubview(iconView)
        hStack.addArrangedSubview(vStack)
        button.addSubview(hStack)

        hStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
        }
        button.snp.makeConstraints { $0.height.equalTo(80) }
        button.addAction(UIAction { [weak self] _ in
            let alert = UIAlertController(title: title, message: "跳转到\(title)页面", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            self?.present(alert, animated: true)
        }, for: .touchUpInside)
        return button
    }
}

// MARK: - 我的页
class ProfileViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "我"
        setupUI()
    }

    private func setupUI() {
        let scrollView = UIScrollView()
        let contentView = UIView()
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        let avatar = UIImageView(image: UIImage(systemName: "person.circle.fill"))
        avatar.tintColor = .systemGray3
        avatar.contentMode = .scaleAspectFit

        let nameLabel = UILabel()
        nameLabel.text = "用户昵称"
        nameLabel.font = .systemFont(ofSize: 20, weight: .semibold)

        let descLabel = UILabel()
        descLabel.text = "这个人很懒，什么都没有留下"
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .systemGray

        let statsStack = UIStackView()
        statsStack.axis = .horizontal
        statsStack.distribution = .fillEqually
        statsStack.spacing = 20
        [("128", "关注"), ("1.2K", "粉丝"), ("5.6K", "获赞")].forEach {
            statsStack.addArrangedSubview(makeStatView(number: $0.0, title: $0.1))
        }

        let editBtn = UIButton(type: .system)
        editBtn.setTitle("编辑资料", for: .normal)
        editBtn.backgroundColor = .systemRed
        editBtn.setTitleColor(.white, for: .normal)
        editBtn.layer.cornerRadius = 20
        editBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)

        [avatar, nameLabel, descLabel, statsStack, editBtn].forEach { contentView.addSubview($0) }

        avatar.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(30)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(80)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatar.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
        statsStack.snp.makeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(60)
            make.height.equalTo(60)
        }
        editBtn.snp.makeConstraints { make in
            make.top.equalTo(statsStack.snp.bottom).offset(30)
            make.centerX.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-50)
        }
    }

    private func makeStatView(number: String, title: String) -> UIView {
        let container = UIView()
        let numLabel = UILabel()
        numLabel.text = number
        numLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        numLabel.textAlignment = .center
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .systemGray
        titleLabel.textAlignment = .center
        container.addSubview(numLabel)
        container.addSubview(titleLabel)
        numLabel.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(numLabel.snp.bottom).offset(4)
            make.centerX.bottom.equalToSuperview()
        }
        return container
    }
}

// MARK: - 工具函数（私有）
private func makeCenterLabel(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .systemFont(ofSize: 24, weight: .medium)
    label.textAlignment = .center
    label.textColor = .systemGray
    return label
}

// MARK: - UIView 链式约束辅助（让 addSubview 后直接 .snp 更简洁）
private extension UIView {
    @discardableResult
    func addSubview<V: UIView>(_ view: V) -> V {
        addSubview(view as UIView)
        return view
    }
}
