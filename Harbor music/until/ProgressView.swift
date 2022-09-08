//
//  ProgressView.swift
//  RxSwiftTest
//
//  Created by ZH_RaySharp on 2022/2/10.
//

import UIKit

enum ProgressStyle: Int {
    case normal // 圆角
    case rect   // 方形
}

class ProgressView: UIView {
    // 进度范围Int min ~ max
    public var progress: Int = 0 {
        didSet {
            if progress >= max {
                progress = max
            }
            if progress <= min {
                progress = min
            }
            arrow.text = "\(Int(progress))"
            setNeedsDisplay()
        }
    }
    // 最大值
    var max: Int = 100
    // 最小值
    var min: Int = 0
    // 步长
    var step: Int = 1
    // 背景色
    public var bgColor: UIColor? = UIColor.lightGray { didSet { baseLayer.backgroundColor = bgColor?.cgColor } }
    // 进度条颜色
    public var progressColor = UIColor.blue
    // 进度条高度
    public var lineHeight = 4.0
    // 滑块大小
    public var sliderSize = CGSize(width: 20.0, height: 20.0)
    // 边距 边距的大小取决于slider的大小，可能导致slider显示不全，如果没有slider可以为0
    public let margin: CGFloat = 20.0
    // 滑块图片
    public var sliderImage: UIImage? {
        didSet {
            let slider = UIImageView(image: sliderImage)
            slider.frame.size = sliderSize
            slider.frame.origin = CGPoint(x: 0, y: 0)
            addSubview(slider)
            self.slider = slider
        }
    }
    // 箭头标识
    public var arrow = ArrowMark()
    // 滑块
    public var slider: UIImageView?
    // 进度条样式
    private var style: ProgressStyle = .normal
    // 闭包
    private var seek: ((Int) -> Void)?
    // 手势正在操作, 设置progress无效
    private(set) var isDrag = false
    // 进度条图层
    private lazy var baseLayer: CALayer = {
        let layer = CALayer()
        layer.frame = CGRect(
            x: 0,
            y: (self.frame.height - lineHeight) * 0.5,
            width: self.frame.width,
            height: lineHeight
        )
        if style == .normal {
            layer.cornerRadius = lineHeight / 2
        }
        layer.backgroundColor = UIColor.lightGray.cgColor
        self.layer.addSublayer(layer)
        return layer
    }()
    private lazy var topBar: UIView = {
        let topBar = UIView()
        if style == .normal {
            topBar.layer.cornerRadius = lineHeight / 2
        }
        topBar.backgroundColor = progressColor
        self.addSubview(topBar)
        return topBar
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    ///
    /// - Parameter style: 进度条样式
    /// - Parameter seekCallback: seek的回调，不传禁用seek，回调参数是进度
    ///
    ///  注意如果要使用箭头标识，View的高度设置必须要大于等于 2 * arrow.height + lineHeight，以保证箭头初次显示的位置正确
    init(style: ProgressStyle, seekCallback: ((Int) -> Void)? = nil) {
        self.style = style
        self.seek = seekCallback
        super.init(frame: .zero)
        self.backgroundColor = .clear
        addSubview(arrow)
        arrow.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 40, height: 20))
        }
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGesture(gesture:)))
        self.addGestureRecognizer(panGesture)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGesture(gesture:)))
        self.addGestureRecognizer(tapGesture)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        baseLayer.frame = CGRect(
            x: margin,
            y: (self.frame.height - lineHeight) * 0.5,
            width: self.frame.width - 2 * margin,
            height: lineHeight
        )
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let y = (self.frame.height - lineHeight) * 0.5
        let progressWidth = self.frame.width - 2 * margin
        let duration: CFTimeInterval = seek == nil ? 0.25 : 0
        // 进度条
        UIView.animate(withDuration: duration) { [self] in
            topBar.frame = CGRect(
                x: margin,
                y: y,
                width: progressWidth * (CGFloat(progress) / CGFloat(max)),
                height: lineHeight
            )
        }

        // 滑块
        if let slider = slider {
            bringSubviewToFront(slider)
            UIView.animate(withDuration: duration) { [self] in
                slider.frame = CGRect(
                    x: progressWidth * (CGFloat(progress) / CGFloat(max)) + self.margin - sliderSize.width * 0.5,
                    y: y + 0.5 * (lineHeight - sliderSize.height),
                    width: sliderSize.width,
                    height: sliderSize.height
                )
            }
        }
        // 箭头标签
        var arrowX = progressWidth * (CGFloat(progress) / CGFloat(max)) + margin - 0.5 * (arrow.bounds.size.width + lineHeight)
        arrowX = arrowX < 0 ? 0 : arrowX
        arrow.frame.origin = CGPoint(
            x: arrowX,
            y: 0.5 * (self.bounds.size.height - lineHeight) - arrow.bounds.size.height
        )
    }
}

// 手势
extension ProgressView {
    @objc func panGesture(gesture: UIPanGestureRecognizer) {
        guard let seek = seek else { return }
        progress = calculateProgress(gesture.location(in: self).x - 20)
        switch gesture.state {
        case .began:
            isDrag = true
        case .ended, .cancelled, .failed:
            isDrag = false
        default: break
        }
        if !isDrag {
            seek(progress)
        }
    }

    @objc func tapGesture(gesture: UITapGestureRecognizer) {
        guard let seek = seek else { return }
        progress = calculateProgress(gesture.location(in: self).x - 20)
        seek(progress)
    }

    /// 通过真实位置和步长计算出progress
    private func calculateProgress(_ positionX: CGFloat) -> Int {
        var x = positionX <= 0 ? 0 : positionX
        x = x >= (self.frame.width - 2 * margin) ? (self.frame.width - 2 * margin) : x
        let progress = x / (self.frame.width - 2 * margin) * CGFloat(max)
        if progress == 0 {
            return 0
        }
        if Int(progress * 10) % (step * 5) >= 0 {
            return Int(progress) + 1
        } else {
            return Int(progress)
        }
    }
}

// MARK: 剪头指示类
class ArrowMark: UIView {
    var suffix: String? = ""
    var text: String = "0" {
        didSet {
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let path = UIBezierPath.init(
            roundedRect: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height - 3),
            cornerRadius: self.frame.height * 0.5
        )
        UIColor.blue.set()
        path.fill()

        let arrowPath = UIBezierPath.init()
        let centerX = self.frame.width * 0.5
        arrowPath.move(to: CGPoint(x: centerX, y: self.frame.height))
        arrowPath.addLine(to: CGPoint(x: centerX - 3, y: self.frame.height - 4))
        arrowPath.addLine(to: CGPoint(x: centerX + 3, y: self.frame.height - 4))
        arrowPath.fill()

        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let attributes = [
            NSAttributedString.Key.font: UIFont .systemFont(ofSize: 14),
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.paragraphStyle: style
        ]

        let progress = text + (suffix ?? "")
        (progress as NSString).draw(
            in: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height),
            withAttributes: attributes
        )
    }
}
