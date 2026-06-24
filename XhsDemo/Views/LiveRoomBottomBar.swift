import UIKit
import SnapKit

final class LiveRoomBottomBar: UIView {

    var onLikeTap: (() -> Void)?

    private let likeButton   = makeBarButton(icon: "heart.fill",           tint: .systemPink)
    private let shareButton  = makeBarButton(icon: "square.and.arrow.up",  tint: .white)
    private let commentField = makeCommentField()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        // 半透明毛玻璃背景
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        addSubview(blur)
        blur.snp.makeConstraints { $0.edges.equalToSuperview() }

        addSubview(commentField)
        addSubview(likeButton)
        addSubview(shareButton)

        commentField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
            make.trailing.equalTo(likeButton.snp.leading).offset(-12)
        }
        likeButton.snp.makeConstraints { make in
            make.trailing.equalTo(shareButton.snp.leading).offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(36)
        }
        shareButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(36)
        }

        likeButton.addAction(UIAction { [weak self] _ in
            self?.animateLike()
            self?.onLikeTap?()
        }, for: .touchUpInside)
    }

    private func animateLike() {
        UIView.animate(withDuration: 0.1) {
            self.likeButton.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.likeButton.transform = .identity
            }
        }
    }
}

private func makeBarButton(icon: String, tint: UIColor) -> UIButton {
    let btn = UIButton(type: .system)
    btn.setImage(UIImage(systemName: icon), for: .normal)
    btn.tintColor = tint
    btn.backgroundColor = UIColor.white.withAlphaComponent(0.15)
    btn.layer.cornerRadius = 18
    return btn
}

private func makeCommentField() -> UITextField {
    let tf = UITextField()
    tf.placeholder = "说点什么..."
    tf.attributedPlaceholder = NSAttributedString(
        string: "说点什么...",
        attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.6)]
    )
    tf.textColor = .white
    tf.font = .systemFont(ofSize: 14)
    tf.backgroundColor = UIColor.white.withAlphaComponent(0.15)
    tf.layer.cornerRadius = 18
    tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
    tf.leftViewMode = .always
    tf.returnKeyType = .send
    return tf
}
