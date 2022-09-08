//
//  TalkRecordAnimationV.swift
//  SmartCam View
//
//  Created by Fanbaili on 2022/2/25.
//

import UIKit

class TalkRecordAnimationV: UIView {
    private let topMoveImageV: UIImageView = {
        let imageV = UIImageView.init(image: UIImage(named: "voice_animation"))
        return imageV
    }()
    private let bottomMoveImageV: UIImageView = {
        let imageV = UIImageView.init(image: UIImage(named: "voice_animation"))
        return imageV
    }()
    private let maskTopView: UIView = {
        let maskView = UIView()
        maskView.backgroundColor = .clear
        maskView.layer.cornerRadius = 15
        return maskView
    }()
    init() {
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.clipsToBounds = true
        self.addSubview(topMoveImageV)
        topMoveImageV.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.centerY.equalToSuperview().offset(-5)
            make.height.equalTo(40)
        }
        self.addSubview(bottomMoveImageV)
        bottomMoveImageV.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.centerY.equalToSuperview().offset(-5)
            make.height.equalTo(40)
        }
        self.addSubview(maskTopView)
        self.changeStyle()
    }
    var gradientLayer = CAGradientLayer.init()
    override func layoutSubviews() {
        super.layoutSubviews()
        let backColor = UIColor.white
        let maskBackColor = UIColor.white.withAlphaComponent(0.4)
        maskTopView.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-5)
            make.left.right.equalTo(0)
            make.height.equalTo(41)
        }
        let gradientColors = [
            backColor.cgColor,
            maskBackColor.cgColor,
            maskBackColor.cgColor,
            backColor.cgColor
        ]
        gradientLayer.removeFromSuperlayer()
        gradientLayer = CAGradientLayer.init()
        gradientLayer.colors = gradientColors
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.frame = maskTopView.bounds
        maskTopView.layer.addSublayer(gradientLayer)
    }
    private func changeStyle() {
        self.bottomMoveImageV.transform = CGAffineTransform.identity
        UIView.animate(withDuration: 0.15) {[weak self] in
            self?.topMoveImageV.alpha = 0
            self?.bottomMoveImageV.alpha = 1
            self?.topMoveImageV.transform = CGAffineTransform(
                translationX: -5, y: 0)
        } completion: {[weak self] _ in
            self?.topMoveImageV.transform = CGAffineTransform.identity
            self?.topMoveImageV.alpha = 1
            self?.bottomMoveImageV.alpha = 0
            UIView.animate(withDuration: 0.2) {[weak self] in
                self?.bottomMoveImageV.transform = CGAffineTransform(
                    translationX: -15, y: 0)
            } completion: { _ in
            }
            self?.changeStyle()
        }
    }
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let backColor = UIColor.white.withAlphaComponent(0.1)
        let cirRect = CGRect(x: 0, y: 0, width: rect.width, height: rect.height - 15)
        let linePath = UIBezierPath.init(
            roundedRect: cirRect,
            byRoundingCorners: [.bottomLeft, .bottomRight, .topLeft, .topRight],
            cornerRadii: CGSize(width: 15, height: 15))
        backColor.set()
        linePath.fill()
        

        linePath.lineWidth = 5
        linePath.lineCapStyle = .round
        linePath.lineJoinStyle = .round
        linePath.move(to: CGPoint(x: rect.width / 2 - 10, y: rect.height - 15))
        linePath.addLine(to: CGPoint(x: rect.width / 2, y: rect.height - 5))
        linePath.addLine(to: CGPoint(x: rect.width / 2 + 10, y: rect.height - 15))
        backColor.set()
        linePath.fill()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
                setNeedsLayout()
            }
        }
    }
}
