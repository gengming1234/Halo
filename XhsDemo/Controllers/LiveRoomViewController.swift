import UIKit
import SnapKit
import Combine

final class LiveRoomViewController: UIViewController {

    // MARK: - ViewModel
    private let viewModel: LiveRoomViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI
    private let backgroundView = UIView()
    private let headerView     = LiveRoomHeaderView()
    private let danmakuView    = DanmakuView()
    private let bottomBar      = LiveRoomBottomBar()

    // MARK: - 初始化
    init(viewModel: LiveRoomViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.startStream()
        danmakuView.startDisplayLink()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.stopStream()
        danmakuView.stopDisplayLink()
    }

    override var prefersStatusBarHidden: Bool { true }

    // MARK: - 绑定
    private func bindViewModel() {
        // 新弹幕到达 → 交给 DanmakuView 渲染
        viewModel.$danmaku
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] danmaku in
                self?.danmakuView.addDanmaku(danmaku)
            }
            .store(in: &cancellables)

        // 观看人数变化 → 更新顶部显示
        viewModel.$viewerCount
            .receive(on: RunLoop.main)
            .sink { [weak self] count in
                self?.headerView.updateViewerCount(count)
            }
            .store(in: &cancellables)
    }

    // MARK: - UI 搭建
    private func setupUI() {
        // 背景：渐变色模拟直播画面
        view.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { $0.edges.equalToSuperview() }
        setupGradient()

        // 顶部主播信息
        view.addSubview(headerView)
        headerView.configure(with: viewModel.room)
        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
        }

        // 弹幕层（全屏，在背景上方、底部栏下方）
        view.addSubview(danmakuView)
        danmakuView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-80)
        }

        // 底部工具栏
        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(60)
        }

        // 关闭按钮（右上角）
        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeBtn.tintColor = .white
        closeBtn.contentVerticalAlignment   = .fill
        closeBtn.contentHorizontalAlignment = .fill
        closeBtn.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        }, for: .touchUpInside)

        view.addSubview(closeBtn)
        closeBtn.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.trailing.equalToSuperview().offset(-16)
            make.width.height.equalTo(32)
        }
    }

    private func setupGradient() {
        let gradient = CAGradientLayer()
        gradient.frame  = UIScreen.main.bounds
        gradient.colors = [
            viewModel.room.coverColor.withAlphaComponent(0.9).cgColor,
            viewModel.room.coverColor.withAlphaComponent(0.4).cgColor,
            UIColor.black.withAlphaComponent(0.8).cgColor
        ]
        gradient.locations = [0, 0.5, 1]
        backgroundView.layer.addSublayer(gradient)
    }
}

// MARK: - LiveRoomHeaderView（主播信息 + 在线人数）
final class LiveRoomHeaderView: UIView {

    private let avatarView    = UIImageView()
    private let hostNameLabel = UILabel()
    private let viewerLabel   = UILabel()
    private let liveTagView   = makeLiveTag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with room: LiveRoom) {
        hostNameLabel.text = room.hostName
        updateViewerCount(room.viewerCount)
    }

    func updateViewerCount(_ count: Int) {
        let formatted = count >= 10000
            ? String(format: "%.1f万", Double(count) / 10000)
            : "\(count)"
        viewerLabel.text = "\(formatted)人在看"
    }

    private func setupUI() {
        // 头像
        avatarView.image            = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor        = .white
        avatarView.contentMode      = .scaleAspectFill
        avatarView.layer.cornerRadius = 20
        avatarView.clipsToBounds    = true
        avatarView.backgroundColor  = UIColor.white.withAlphaComponent(0.2)

        // 主播名
        hostNameLabel.font      = .systemFont(ofSize: 15, weight: .semibold)
        hostNameLabel.textColor = .white

        // 在线人数
        viewerLabel.font      = .systemFont(ofSize: 12)
        viewerLabel.textColor = UIColor.white.withAlphaComponent(0.8)

        let nameStack = UIStackView(arrangedSubviews: [hostNameLabel, viewerLabel])
        nameStack.axis    = .vertical
        nameStack.spacing = 2

        let container = UIView()
        container.backgroundColor    = UIColor.black.withAlphaComponent(0.3)
        container.layer.cornerRadius = 28

        [avatarView, nameStack, liveTagView].forEach { container.addSubview($0) }

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        nameStack.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }
        liveTagView.snp.makeConstraints { make in
            make.leading.equalTo(nameStack.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-12)
        }

        addSubview(container)
        container.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(56)
        }
    }
}

private func makeLiveTag() -> UIView {
    let bg = UIView()
    bg.backgroundColor    = .systemRed
    bg.layer.cornerRadius = 4

    let label = UILabel()
    label.text      = "直播中"
    label.font      = .systemFont(ofSize: 11, weight: .bold)
    label.textColor = .white

    bg.addSubview(label)
    label.snp.makeConstraints { make in
        make.edges.equalToSuperview().inset(UIEdgeInsets(top: 3, left: 6, bottom: 3, right: 6))
    }
    return bg
}
