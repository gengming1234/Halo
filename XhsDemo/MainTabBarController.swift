import UIKit

// MARK: - MainTabBarController
//
// 【职责】：只负责搭建 TabBar 的骨架结构，创建各个 Tab 的 VC
// 【不做的事】：不包含任何业务逻辑，子页面的所有逻辑各自在对应文件里

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBarAppearance()
        setupViewControllers()
    }

    private func setupTabBarAppearance() {
        tabBar.backgroundColor = .white
        tabBar.tintColor = .systemRed
        tabBar.unselectedItemTintColor = .systemGray
        tabBar.layer.borderWidth = 0.5
        tabBar.layer.borderColor = UIColor.systemGray5.cgColor
        tabBar.isTranslucent = false
    }

    private func setupViewControllers() {
        // 首页：UIColViewContainer（包含发现/关注/附近三个子页面）
        let homeNav = makeNav(root: UIColViewContainer(),
                              title: "首页",
                              image: "house",
                              selectedImage: "house.fill")

        // 购物
        let shopNav = makeNav(root: ShopViewController(),
                              title: "购物",
                              image: "bag",
                              selectedImage: "bag.fill")

        // 发布（中间加号）
        let publishNav = makeNav(root: PublishViewController(),
                                 title: "",
                                 image: "plus.circle",
                                 selectedImage: "plus.circle.fill")
        publishNav.tabBarItem.imageInsets = UIEdgeInsets(top: -5, left: 0, bottom: 5, right: 0)

        // 消息
        let messageNav = makeNav(root: MessageViewController(),
                                 title: "消息",
                                 image: "message",
                                 selectedImage: "message.fill")

        // 我的
        let profileNav = makeNav(root: ProfileViewController(),
                                 title: "我",
                                 image: "person",
                                 selectedImage: "person.fill")

        viewControllers = [homeNav, shopNav, publishNav, messageNav, profileNav]
    }

    // 工厂方法：创建带 NavController 的 TabBar 子项
    private func makeNav(root: UIViewController,
                         title: String,
                         image: String,
                         selectedImage: String) -> UINavigationController {
        let nav = UINavigationController(rootViewController: root)
        nav.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: image),
            selectedImage: UIImage(systemName: selectedImage)
        )
        return nav
    }

    // 发布按钮点击动画
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let items = tabBar.items,
              let index = items.firstIndex(of: item),
              index == 2 else { return }
        animatePublishButton()
    }

    private func animatePublishButton() {
        guard let btn = tabBar.subviews.first(where: {
            $0.frame.origin.x > tabBar.frame.width * 0.4 &&
            $0.frame.origin.x < tabBar.frame.width * 0.6
        }) else { return }

        UIView.animate(withDuration: 0.1) {
            btn.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) { btn.transform = .identity }
        }
    }
}
