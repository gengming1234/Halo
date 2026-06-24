import UIKit
import SnapKit
import Kingfisher
import Combine

final class NoteDetailViewController: UIViewController {

    // MARK: - ViewModel
    private let viewModel: NoteDetailViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI
    private lazy var scrollView: UIScrollView = {
        let v = UIScrollView()
        v.alwaysBounceVertical = true
        v.backgroundColor = .white
        return v
    }()

    private lazy var contentView = UIView()

    private lazy var mainImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.layer.cornerRadius = 12
        v.isUserInteractionEnabled = true
        v.backgroundColor = .systemGray6
        return v
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .semibold)
        l.numberOfLines = 0
        return l
    }()

    private lazy var contentLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16)
        l.numberOfLines = 0
        l.textColor = .darkGray
        l.lineBreakMode = .byWordWrapping
        return l
    }()

    private let bottomBarContainer = UIView()

    private lazy var bottomToolbar: UIToolbar = {
        let t = UIToolbar()
        t.backgroundColor = .white
        t.tintColor = .systemRed
        return t
    }()

    private var likeBarButton: UIBarButtonItem!
    private var collectBarButton: UIBarButtonItem!

    // MARK: - 初始化
    init(viewModel: NoteDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        setupNavBar()
        bindViewModel()
        fillContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    // MARK: - 绑定
    private func bindViewModel() {
        viewModel.$isLiked
            .receive(on: RunLoop.main)
            .sink { [weak self] isLiked in
                self?.likeBarButton.image = UIImage(systemName: isLiked ? "heart.fill" : "heart")
            }
            .store(in: &cancellables)

        viewModel.$isCollected
            .receive(on: RunLoop.main)
            .sink { [weak self] isCollected in
                self?.collectBarButton.image = UIImage(systemName: isCollected ? "star.fill" : "star")
            }
            .store(in: &cancellables)

        viewModel.$isFollowing
            .receive(on: RunLoop.main)
            .sink { [weak self] isFollowing in
                self?.updateFollowButtonAppearance(isFollowing: isFollowing)
            }
            .store(in: &cancellables)
    }

    // MARK: - 填充数据
    private func fillContent() {
        titleLabel.text = viewModel.note.title
        contentLabel.text = viewModel.note.content
        mainImageView.kf.setImage(
            with: viewModel.displayImageURL,
            placeholder: UIImage(systemName: "photo")
        )
    }
}

// MARK: - UI 设置
private extension NoteDetailViewController {

    func setupUI() {
        view.addSubview(scrollView)
        view.addSubview(bottomBarContainer)
        scrollView.addSubview(contentView)
        contentView.addSubview(mainImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        bottomBarContainer.addSubview(bottomToolbar)

        setupToolbar()
        setupConstraints()

        let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        mainImageView.addGestureRecognizer(tap)
    }

    func setupConstraints() {
        bottomBarContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(56)
        }
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomBarContainer.snp.top)
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        mainImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(280)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(mainImageView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-20)
        }
        bottomToolbar.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    func setupToolbar() {
        likeBarButton = UIBarButtonItem(
            image: UIImage(systemName: "heart"),
            primaryAction: UIAction { [weak self] _ in
                self?.viewModel.toggleLike()
            }
        )

        let commentButton = UIBarButtonItem(
            image: UIImage(systemName: "message"),
            primaryAction: UIAction { _ in print("评论") }
        )

        collectBarButton = UIBarButtonItem(
            image: UIImage(systemName: "star"),
            primaryAction: UIAction { [weak self] _ in
                self?.viewModel.toggleCollect()
            }
        )

        let shareButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            primaryAction: UIAction { _ in print("分享") }
        )

        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let sp = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        sp.width = 12
        bottomToolbar.items = [flex, likeBarButton, sp, commentButton, sp, collectBarButton, sp, shareButton]
    }

    func setupNavBar() {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8

        let avatar = UIImageView()
        avatar.image = UIImage(systemName: "person.circle.fill")
        avatar.tintColor = .systemGray3
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 16
        avatar.snp.makeConstraints { $0.width.height.equalTo(32) }

        let nameLabel = UILabel()
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.text = viewModel.note.author

        stack.addArrangedSubview(avatar)
        stack.addArrangedSubview(nameLabel)
        navigationItem.titleView = stack

        let followBtn = buildFollowButton()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: followBtn)
    }

    func buildFollowButton() -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("关注", for: .normal)
        btn.setTitleColor(.systemRed, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        btn.layer.cornerRadius = 14
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.systemRed.cgColor
        btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        btn.snp.makeConstraints { make in
            make.height.equalTo(28)
            make.width.greaterThanOrEqualTo(56)
        }
        btn.addAction(UIAction { [weak self] _ in
            self?.viewModel.followAuthor()
        }, for: .touchUpInside)
        return btn
    }

    func updateFollowButtonAppearance(isFollowing: Bool) {
        guard let btn = navigationItem.rightBarButtonItem?.customView as? UIButton else { return }
        let color: UIColor = isFollowing ? .systemGray : .systemRed
        btn.setTitle(isFollowing ? "已关注" : "关注", for: .normal)
        btn.setTitleColor(color, for: .normal)
        btn.layer.borderColor = color.cgColor
        btn.isEnabled = !isFollowing
    }

    @objc func imageTapped() {
        print("图片被点击，可以跳转查看大图")
    }
}
