import UIKit
import SnapKit

// 直播列表：横向滚动的直播间卡片行
// 嵌入 DiscoverFeedViewController 顶部
final class LiveListViewController: UIViewController {

    private let rooms = LiveRoom.mockData
    private var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupCollectionView()
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection       = .horizontal
        layout.itemSize              = CGSize(width: 90, height: 120)
        layout.minimumInteritemSpacing = 12
        layout.sectionInset          = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .white
        collectionView.dataSource      = self
        collectionView.delegate        = self
        collectionView.register(LiveRoomCell.self, forCellWithReuseIdentifier: LiveRoomCell.reuseID)

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}

// MARK: - DataSource / Delegate
extension LiveListViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        rooms.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: LiveRoomCell.reuseID, for: indexPath
        ) as! LiveRoomCell
        cell.configure(with: rooms[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let room = rooms[indexPath.item]
        // 通过路由系统跳转，不直接依赖 LiveRoomViewController
        AppRouter.shared.navigate(to: LiveRoomRoutable.self, from: self) { context in
            (context as? LiveRoomContext)?.room = room
        }
    }
}

// MARK: - LiveRoomCell（直播间卡片）
final class LiveRoomCell: UICollectionViewCell {

    static let reuseID = "LiveRoomCell"

    private let coverView    = UIView()
    private let liveTag      = UILabel()
    private let viewerLabel  = UILabel()
    private let titleLabel   = UILabel()
    private let hostLabel    = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with room: LiveRoom) {
        coverView.backgroundColor = room.coverColor.withAlphaComponent(0.8)

        let count = room.viewerCount >= 10000
            ? String(format: "%.1f万", Double(room.viewerCount) / 10000)
            : "\(room.viewerCount)"
        viewerLabel.text = "👁 \(count)"
        titleLabel.text  = room.title
        hostLabel.text   = room.hostName
    }

    private func setupUI() {
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds      = true

        // 封面背景
        coverView.layer.cornerRadius = 12
        contentView.addSubview(coverView)
        coverView.snp.makeConstraints { $0.edges.equalToSuperview() }

        // 直播标签
        liveTag.text            = "🔴 直播"
        liveTag.font            = .systemFont(ofSize: 9, weight: .bold)
        liveTag.textColor       = .white
        liveTag.backgroundColor = UIColor.systemRed.withAlphaComponent(0.85)
        liveTag.layer.cornerRadius = 4
        liveTag.clipsToBounds   = true
        liveTag.textAlignment   = .center
        coverView.addSubview(liveTag)
        liveTag.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(6)
            make.height.equalTo(16)
            make.width.equalTo(44)
        }

        // 观看人数
        viewerLabel.font      = .systemFont(ofSize: 9)
        viewerLabel.textColor = .white
        coverView.addSubview(viewerLabel)
        viewerLabel.snp.makeConstraints { make in
            make.top.equalTo(liveTag.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(6)
        }

        // 主播名
        hostLabel.font      = .systemFont(ofSize: 10, weight: .medium)
        hostLabel.textColor = .white
        hostLabel.textAlignment = .center
        coverView.addSubview(hostLabel)
        hostLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-4)
            make.leading.trailing.equalToSuperview().inset(4)
        }

        // 标题
        titleLabel.font          = .systemFont(ofSize: 10)
        titleLabel.textColor     = UIColor.white.withAlphaComponent(0.85)
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        coverView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(hostLabel.snp.top).offset(-2)
            make.leading.trailing.equalToSuperview().inset(4)
        }

        // 暗色渐变蒙层（让文字更清晰）
        let grad = CAGradientLayer()
        grad.frame  = CGRect(x: 0, y: 40, width: 90, height: 80)
        grad.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.6).cgColor]
        coverView.layer.addSublayer(grad)
    }
}
