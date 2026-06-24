import UIKit
import SnapKit
import Combine

final class DiscoverFeedViewController: UIViewController {

    // MARK: - ViewModel
    private let viewModel: DiscoverViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI
    var collectionView: UICollectionView!

    private let secondaryScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.backgroundColor = .white
        return sv
    }()

    private let secondaryStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 20
        sv.alignment = .center
        return sv
    }()

    private var categoryButtons: [UIButton] = []

    // 直播列表（嵌入顶部）
    private let liveListVC = LiveListViewController()
    private let liveListHeight: CGFloat = 136

    // MARK: - 初始化
    init(viewModel: DiscoverViewModel = DiscoverViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupCategoryBar()
        setupLiveList()
        setupCollectionView()
        setupReorderGesture()
        bindViewModel()
        viewModel.loadNotes()
    }

    // MARK: - 绑定
    private func bindViewModel() {
        viewModel.$notes
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] notes in
                guard let self else { return }
                self.collectionView.reloadData()
                if !notes.isEmpty {
                    self.collectionView.scrollToItem(
                        at: IndexPath(item: 0, section: 0),
                        at: .top,
                        animated: false
                    )
                }
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { message in
                print("加载失败：\(message)")
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: RunLoop.main)
            .sink { _ in }
            .store(in: &cancellables)
    }
}

// MARK: - UI 设置
private extension DiscoverFeedViewController {

    func setupLiveList() {
        addChild(liveListVC)
        view.addSubview(liveListVC.view)
        liveListVC.didMove(toParent: self)

        liveListVC.view.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(liveListHeight)
        }
    }

    func setupCategoryBar() {
        view.addSubview(secondaryScrollView)
        secondaryScrollView.addSubview(secondaryStackView)

        secondaryScrollView.snp.makeConstraints { make in
            make.top.equalTo(liveListVC.view.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        secondaryStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
            make.height.equalToSuperview()
        }

        for (index, title) in viewModel.categories.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(title, for: .normal)
            btn.tag = index
            btn.setTitleColor(index == 0 ? .black : .systemGray, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 15, weight: index == 0 ? .bold : .regular)
            btn.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
            secondaryStackView.addArrangedSubview(btn)
            categoryButtons.append(btn)
        }

        let line = UIView()
        line.backgroundColor = .systemGray6
        view.addSubview(line)
        line.snp.makeConstraints { make in
            make.top.equalTo(secondaryScrollView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 12
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)

        let columns: CGFloat = 2
        let itemWidth = (view.bounds.width - spacing * (columns + 1)) / columns
        let padding: CGFloat = 10
        let coverH = (itemWidth - padding * 2) * 4.0 / 3.0
        let itemHeight = padding * 2 + coverH + 8 + 44 + 6 + 18
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(NoteCell.self, forCellWithReuseIdentifier: NoteCell.reuseID)

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(secondaryScrollView.snp.bottom).offset(1)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    func setupReorderGesture() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleReorder(_:)))
        longPress.minimumPressDuration = 0.3
        collectionView.addGestureRecognizer(longPress)
    }
}

// MARK: - 用户交互
extension DiscoverFeedViewController {

    @objc private func categoryTapped(_ sender: UIButton) {
        let index = sender.tag
        viewModel.selectCategory(at: index)
        updateCategoryStyle(selectedIndex: index)
    }

    private func updateCategoryStyle(selectedIndex: Int) {
        for (i, btn) in categoryButtons.enumerated() {
            btn.setTitleColor(i == selectedIndex ? .black : .systemGray, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 15, weight: i == selectedIndex ? .bold : .regular)
        }
    }

    @objc private func handleReorder(_ gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: collectionView)
        switch gesture.state {
        case .began:
            guard let ip = collectionView.indexPathForItem(at: point) else { return }
            collectionView.beginInteractiveMovementForItem(at: ip)
        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(point)
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }
}

// MARK: - UICollectionViewDataSource
extension DiscoverFeedViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return viewModel.notes.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: NoteCell.reuseID, for: indexPath
        ) as! NoteCell

        let note = viewModel.note(at: indexPath.item)
        cell.configure(with: note)
        cell.onDetailTap = {
            print("点击了作者 [\(note.author)] 的信息")
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        moveItemAt sourceIndexPath: IndexPath,
                        to destinationIndexPath: IndexPath) {
        viewModel.moveNote(from: sourceIndexPath.item, to: destinationIndexPath.item)
    }
}

// MARK: - UICollectionViewDelegate
extension DiscoverFeedViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        let note = viewModel.note(at: indexPath.item)
        let detailVM = NoteDetailViewModel(note: note)
        let detailVC = NoteDetailViewController(viewModel: detailVM)
        navigationItem.backButtonTitle = ""
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
