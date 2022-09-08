//
//  AlertView.swift
//  SmartCam View
//
//  Created by ZH_RaySharp on 2021/1/4.
//  Copyright © 2021 ZH_RaySharp. All rights reserved.
//

import UIKit
import SnapKit
import RxCocoa
import RxSwift

class AlertView: UIView {
    deinit {
        NSLog("%@", "AlertView dismiss")
    }
    enum ButtonsStyle {
        case horizontal, vertical
    }

    private let disposeBag = DisposeBag()
    private var tapOutsideDismiss: Bool
    private var clickActionDismiss: Bool
    private lazy var control: UIControl = {
        let control = UIControl()
        control.frame = UIScreen.main.bounds
        control.backgroundColor = .lightGray
        control.alpha = 0.6
        return control
    }()
    // 标题
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: RSAlertViewStaticParameter.titleFontSize)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        return titleLabel
    }()
    // 中间内容区域
    private var contentView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = RSAlertViewStaticParameter.itemSpace
        stackView.alignment = .fill
        return stackView
    }()
    // 底部按钮区域
    private lazy var buttonContentView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = CGFloat(0)
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        return stackView
    }()

/// 构造函数
///
/// - Parameter tapOutsideDismiss: 是否支持点击空白区域弹窗消失
///  - Parameter clickActionDismiss: 是否支持点击按钮弹窗消失
    init(tapOutsideDismiss: Bool = false, clickActionDismiss: Bool = true) {
        self.tapOutsideDismiss = tapOutsideDismiss
        self.clickActionDismiss = clickActionDismiss
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: 公共接口
extension AlertView {
    public func show() {
        let tap = UITapGestureRecognizer()
        control.addGestureRecognizer(tap)
        tap.rx.event
            .subscribe { [weak self] _ in
                self?.endEditing(true)
                if self?.tapOutsideDismiss == true {
                    self?.dismiss()
                }
            }
            .disposed(by: disposeBag)
        guard let window = UIApplication.shared.exKeyWindow else {
            print("window error")
            return
        }
        window.addSubview(control)
        window.addSubview(self)
        self.snp.makeConstraints { make in
            make.center.equalTo(window.snp.center)
            make.width.equalTo(window.snp.width).multipliedBy(RSAlertViewStaticParameter.scale).priority(.high)
            make.width.lessThanOrEqualTo(RSAlertViewStaticParameter.maxWidth).priority(.required)
        }
    }

    @objc public func dismiss() {
        control.removeFromSuperview()
        self.removeFromSuperview()
    }

/// 添加大标题
/// - Parameter title: 大标题文字
/// - Returns: self
    public func add(title: String) -> Self {
        titleLabel.text = title
        setNeedsLayout()
        return self
    }

/// 添加内容
/// 可以多次调用，可以和addCustom一起使用，多次调用会一直往下增加视图
/// - Parameter message: 内容文字
/// - Returns: self
    public func add(message: String) -> Self {
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .left
        messageLabel.textColor = .black
        if #available(iOS 14.0, *) {
            messageLabel.lineBreakStrategy = []
        }
        contentView.addArrangedSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(40)
        }
        return self
    }

/// 添加富文本内容
/// - Parameter attributeMessage: 内容文字
/// - Returns: self
    public func add(attributeMessage: NSAttributedString) -> Self {
        let messageLabel = UILabel()
        messageLabel.attributedText = attributeMessage
        messageLabel.numberOfLines = 0
        contentView.addArrangedSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(40)
        }
        return self
    }

/// 添加按钮
/// - Parameters:
///   - action: 按钮名称
///   - clicked: 按钮点击事件, 回调上面已添加的所有内容, 例如大标题, 内容, 但不包括已添加的actionButton, 以自主控制当前actionButton的状态
///   - style: 按钮风格化，预留功能
/// - Returns: self
    public func add(
        action buttonTitle: String,
        clicked: @escaping(_ addedData: [Any], _ button: UIButton, _ alert: AlertView) -> Void,
        with style: [ButtonPropertyKey: Any]? = nil
    ) -> Self {
        let button = UIButton(type: .system)
        button.setTitle(buttonTitle, for: .normal)
        var isRounded = false
        var height = RSAlertViewStaticParameter.buttonHeight
        if let style = style {
            style.keys.forEach { key in
                let value = style[key]
                switch key {
                case .titleColor:
                    button.setTitleColor(value as? UIColor, for: .normal)
                case .backgroundColor:
                    button.backgroundColor = value as? UIColor
                case .height:
                    height = value as? Double ?? RSAlertViewStaticParameter.buttonHeight
                case .isRounded:
                    isRounded = value as? Bool ?? false
                }
            }
        } else {
            button.setTitleColor(.blue, for: .normal)
        }
        if isRounded {
            button.clipsToBounds = true
            button.layer.cornerRadius = height * 0.5
        }
        buttonContentView.addArrangedSubview(button)
        button.snp.makeConstraints { make in
            make.height.equalTo(height)
        }

        button.rx.tap.asObservable()
            .subscribe { [weak self, weak button] _ in
                guard let button = button, let self = self else { return }
                clicked(["result"], button, self)
                if self.clickActionDismiss == true {
                    self.dismiss()
                }
            }
            .disposed(by: disposeBag)
        return self
    }

    ///  inserts: 按钮所在stackView距离其他View的内边距
    ///  style: 按钮的格式，竖直或水平方向
    ///  spacing: 按钮间的间距
    public func setButtonStyle(_ style: ButtonsStyle, spacing: CGFloat = 0.0, inserts: UIEdgeInsets? = nil) -> Self {
        switch style {
        case .horizontal:
            buttonContentView.axis = .horizontal
        case .vertical:
            buttonContentView.axis = .vertical
        }
        buttonContentView.spacing = spacing
        if let inserts = inserts {
            buttonContentView.snp.remakeConstraints { make in
                make.top.equalTo(contentView.snp.bottom).offset(inserts.top)
                make.trailing.equalTo(self).offset(inserts.right)
                make.leading.equalTo(self).offset(inserts.left)
                make.bottom.equalTo(self).offset(inserts.bottom)
            }
        }
        self.setNeedsLayout()
        return self
    }

/// 添加自定义视图
/// - Parameter customView: 自定义视图
/// - Returns: self
    public func add(customView: UIView) -> Self {
        contentView.addArrangedSubview(customView)
        return self
    }
}

// MARK: 初始化UI
extension AlertView {
    private func setup() {
        self.layer.cornerRadius = RSAlertViewStaticParameter.cornerRadius
        self.backgroundColor = .white

        addSubview(titleLabel)
        addSubview(contentView)
        addSubview(buttonContentView)

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.snp.top).offset(16)
            make.leading.equalTo(self.snp.leading).offset(RSAlertViewStaticParameter.marginSpace)
            make.centerX.equalTo(self)
            make.height.equalTo(0)
        }

        contentView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.equalTo(self).offset(RSAlertViewStaticParameter.marginSpace)
            make.trailing.equalTo(self).offset(-RSAlertViewStaticParameter.marginSpace)
        }

        buttonContentView.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.bottom)
            make.trailing.equalTo(self)
            make.leading.equalTo(self)
            make.bottom.equalTo(self)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = CGSize(
            width: self.bounds.width - RSAlertViewStaticParameter.marginSpace * 2,
            height: UIScreen.main.bounds.height)
        let labelSize: CGSize = titleLabel.sizeThatFits(size)
        let height = labelSize.height
        titleLabel.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
    }
}

extension UIApplication {
    var exKeyWindow: UIWindow? {
        return UIApplication.shared.delegate?.window ?? nil
        if #available(iOS 13.0, *) {
            if let appdelegate = UIApplication.shared.delegate {
                // 从生物认证界面过来时, 生物认证成功界面会保留一段时间, 此时 UIScene.activationState == foregroundInactive, 所以直接从 AppDelegate 里拿window
                return appdelegate.window ?? UIWindow()
            } else {
                // 从生物认证界面过来时, 生物认证成功界面会保留一段时间, 此时 UIScene.activationState == foregroundInactive, 所以加上直接从 AppDelegate 里拿window
                return  self.connectedScenes
                    .filter { $0.activationState == .foregroundActive }
                    .compactMap { $0 as? UIWindowScene }.first?.windows
                    .first {
                        $0.isKeyWindow
                    }
            }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}

enum RSAlertViewStaticParameter {
    static let cornerRadius: CGFloat = 12
    static let titleFontSize: CGFloat = 20
    static let itemSpace: CGFloat = 0
    static let marginSpace: CGFloat = 24
    static let labelHeight: CGFloat = 40
    static let buttonHeight: CGFloat = 60
    static let scale: CGFloat = 0.75
    static let maxWidth: CGFloat = 450
}

// MARK: 按钮的属性，可自定义添加
enum ButtonPropertyKey: String {
    case height
    case isRounded
    case titleColor
    case backgroundColor
}
