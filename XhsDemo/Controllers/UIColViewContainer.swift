import UIKit
import SnapKit

// MARK: - UIColViewContainer（首页 Tab 容器 + 分页）
//
// 【职责】：管理"发现/关注/附近"三个子页面的切换（Tab + PageViewController）
// 【不含业务逻辑】：只负责"哪个 Tab 对应哪个页面"的容器逻辑

final class UIColViewContainer: UIViewController {

    // MARK: - 顶部三个 Tab 按钮
    private let tabButton1 = UIButton()
    private let tabButton2 = UIButton()
    private let tabButton3 = UIButton()
    private let tabStackView = UIStackView()
    private var currentIndex = 0

    // MARK: - PageViewController（系统分页控制器，负责左右滑）
    private lazy var pageVC: UIPageViewController = {
        let vc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        vc.dataSource = self   // UIKit 要求的代理：提供"前一页/后一页"
        vc.delegate = self     // UIKit 要求的代理：滑动完成后通知我们
        return vc
    }()

    // 三个子页面：每个子页面有自己的 ViewModel
    private lazy var pages: [UIViewController] = [
        DiscoverFeedViewController(viewModel: DiscoverViewModel()),
        FollowViewController(),
        NearbyViewController()
    ]

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupTabButtons()
        setupPageViewController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

// MARK: - UI 设置
private extension UIColViewContainer {

    func setupTabButtons() {
        [("发现", tabButton1), ("关注", tabButton2), ("附近", tabButton3)].enumerated().forEach { i, pair in
            let (title, btn) = pair
            btn.setTitle(title, for: .normal)
            btn.tag = i
            btn.setTitleColor(.gray, for: .normal)
            btn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            tabStackView.addArrangedSubview(btn)
        }

        tabStackView.axis = .horizontal
        tabStackView.distribution = .fillEqually
        view.addSubview(tabStackView)
        tabStackView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview().inset(50)
            make.height.equalTo(50)
        }

        selectTab(tabButton1)  // 默认选中"发现"
    }

    func setupPageViewController() {
        addChild(pageVC)
        view.addSubview(pageVC.view)
        pageVC.view.snp.makeConstraints { make in
            make.top.equalTo(tabStackView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        pageVC.setViewControllers([pages[0]], direction: .forward, animated: false)
        pageVC.didMove(toParent: self)
    }

    @objc func tabTapped(_ sender: UIButton) {
        let idx = sender.tag
        guard idx != currentIndex else { return }
        let dir: UIPageViewController.NavigationDirection = idx > currentIndex ? .forward : .reverse
        currentIndex = idx
        pageVC.setViewControllers([pages[idx]], direction: dir, animated: true)
        selectTab(sender)
    }

    func selectTab(_ selected: UIButton) {
        [tabButton1, tabButton2, tabButton3].forEach { $0.setTitleColor(.gray, for: .normal) }
        selected.setTitleColor(.black, for: .normal)
    }
}

// MARK: - UIPageViewControllerDataSource & Delegate
//
// 【为什么必须用代理】：UIKit 的 UIPageViewController 用代理来询问
//   "往左滑时，前一页是哪个 VC？往右滑时，后一页是哪个 VC？"
//   这是框架规定的通信方式，没有其他选择
extension UIColViewContainer: UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let idx = pages.firstIndex(of: viewController), idx > 0 else { return nil }
        return pages[idx - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let idx = pages.firstIndex(of: viewController), idx < pages.count - 1 else { return nil }
        return pages[idx + 1]
    }
}

extension UIColViewContainer: UIPageViewControllerDelegate {

    // 用户左右滑动完成后，同步更新顶部 Tab 按钮的选中状态
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard completed,
              let vc = pageViewController.viewControllers?.first,
              let idx = pages.firstIndex(of: vc) else { return }
        currentIndex = idx
        selectTab([tabButton1, tabButton2, tabButton3][idx])
    }
}
