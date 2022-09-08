//
//  PlayerView.swift
//  Harbor music
//
//  Created by Wuhuijuan on 2022/9/2.
//

import Foundation
import UIKit
import AVFoundation
import RxSwift
import RxCocoa
import SnapKit

extension VoicePlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playDidFinishedSubject.onNext("")
        NSLog("%@", "已经播放完成")
    }
}

class VoicePlayer: UIView {
    public let playDidFinishedSubject = PublishSubject<String>()
    private var startPlay: (() -> String)?
    private var stopPlay: (() -> Void)?
    public var voicePath: String?
    private var durationTime = 15
    private var voiceTimer: Timer?
    public var player: AVAudioPlayer?
    private let disposeBag = DisposeBag()
    private var progressView = ProgressView.init(style: .normal)
    // MARK: - 初始化
    init() {
        super.init(frame: .zero)
        progressView = ProgressView.init(style: .normal) { [weak self] seek in
            guard let self = self, let player = self.player else { return }
            self.palyAtTime(atTime: TimeInterval((Double(seek) / 100.0) * player.duration))
            let all = Int(((Double(seek) / 100.0) * player.duration))
            let minute = all / 60 % 60
            let second = all % 60
            self.timeLabel.text = NSString(format: "%02d:%02d", minute, second) as String
        }
        progressView.sliderImage = UIImage(named: "doorbell_sliderImage")
        progressView.sliderSize = CGSize(width: 25, height: 25)
        progressView.arrow.isHidden = true
        addSubview(timeLabel)
        addSubview(playButton)
        addSubview(progressView)
    }
    // MARK: - 创建子控件
    lazy private var timeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .black
        label.font = .systemFont(ofSize: 20)
        return label
    }()
    lazy private var playButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "lullaby_play"), for: .normal)
        button.setImage(UIImage(named: "lullaby_audition_pause"), for: .selected)
        button.rx.tap.asObservable()
            .subscribe { [weak self] _ in
                guard let self = self else { return }
                if button.isSelected {
                    self.stopPlayVoice()
                } else {
                    guard let path = self.voicePath else { return }
                    self.startPlayVoice(path: path)
                    self.playDidFinishedSubject.subscribe { [weak self] _ in
                        guard let self = self else { return }
                        self.stopPlayVoice()
                        self.playButton.isSelected = false
                    }
                    .disposed(by: self.disposeBag)
                }
            }
            .disposed(by: disposeBag)
        return button
    }()

    // MARK: - 累积时间
    @objc func onUpdate() {
        guard let player = self.player else {
            return
        }
        let currentTime = Float(player.currentTime)
        if currentTime > 0.0 {
            let durationTime = Float(player.duration)
            let progressTime = Float(currentTime / durationTime)
            progressView.progress = Int(CGFloat(progressTime + 0.1) * 100)
            let all = Int(currentTime)
            let minute = all / 60 % 60
            let second = all % 60
            timeLabel.text = NSString(format: "%02d:%02d", minute, second) as String
        }
    }
    public func startPlayClicked(startPlay: @escaping (() -> String)) {
        self.startPlay = startPlay
    }
    public func stopPlaykClicked(stopPlay: @escaping (() -> Void)) {
        self.stopPlay = stopPlay
    }
    // MARK: - 播放声音
    func startPlayVoice(path: String) {
        playButton.isSelected = true
        let select = #selector(onUpdate)
        voiceTimer = Timer.scheduledTimer(
            timeInterval: 0.05,
            target: self,
            selector: select,
            userInfo: nil,
            repeats: true)
        do {
            let content = URL(fileURLWithPath: path)
            player = try AVAudioPlayer(contentsOf: content)
            guard let player = self.player else {
                return
            }
            if player.isPlaying {
                return
            }
            player.delegate = self
            player.play()
        } catch let err {
            print(err.localizedDescription)
        }
    }
    // MARK: - 播放指定时间段声音
    func palyAtTime(atTime: TimeInterval) {
        playButton.isSelected = true
        let select = #selector(onUpdate)
        voiceTimer = Timer.scheduledTimer(
            timeInterval: 0.05,
            target: self,
            selector: select,
            userInfo: nil,
            repeats: true)
        do {
            guard let path = voicePath else { return }
            guard let content = URL(string: path) else {
                return
            }
            player = try AVAudioPlayer(contentsOf: content)
            guard let player = self.player else {
                return
            }
            player.play(atTime: atTime)
        } catch let err {
            print(err.localizedDescription)
        }
    }
    // MARK: - 暂停声音
    func pausePlayVoice() {
        guard let player = self.player else {
            return
        }
        if player.isPlaying {
            player.pause()
        }
    }
    // MARK: - 停止声音
    func stopPlayVoice() {
        playButton.isSelected = false
        guard let player = self.player else {
            return
        }
        voiceTimer?.invalidate()
        timeLabel.text = "00:00"
        if player.isPlaying {
            player.stop()
        }
        progressView.progress = 0
    }
    // MARK: - 布局子控件
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutSubview()
    }
    private func layoutSubview() {
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(30)
        }
        playButton.snp.makeConstraints { make in
            make.top.equalTo(timeLabel.snp.bottom)
            make.leading.equalTo(self).offset(16)
            make.centerY.equalTo(self)
            make.height.width.equalTo(25)
        }
        progressView.snp.makeConstraints { make in
            make.height.equalTo(8)
            make.centerY.equalTo(self)
            make.leading.equalTo(self).offset(50)
            make.trailing.equalTo(self).offset(-16)
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

