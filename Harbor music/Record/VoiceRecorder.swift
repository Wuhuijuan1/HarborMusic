//
//  RecordView.swift
//  Harbor music
//
//  Created by Wuhuijuan on 2022/9/2.
//

import UIKit
import AVFoundation

class VoiceRecorder: UIView {
    public var musicMode: String = ".aac"
    private var startTalk: (() -> Void)?
    private var stopTalk: ((RecordVoice) -> Void)?
    private var voicePath: String?
    private var recorder: AVAudioRecorder?
    private var recorderSeting: [String: Any]?
    private var currentTime = 0
    private var timerString: String?
    private var voiceTimer: Timer?
    init() {
        super.init(frame: .zero)
        addSubview(topLabel)
        addSubview(animationView)
        addSubview(talkButton)
        addSubview(bottomLabel)
        addSubview(limitLabel)
        initializeRecord()
    }
    // MARK: - 创建子控件
    lazy private var topLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.isHidden = true
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 20)
        label.textColor = UIColor.lightGray
        return label
    }()
    lazy private var animationView: UIView = {
        let view = TalkRecordAnimationV()
        view.isHidden = true
        return view
    }()
    lazy private var talkButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "half_duplex_talk_normal"), for: .normal)
        button.setImage(UIImage(named: "half_duplex_talk_selected"), for: .highlighted)
        button.addTarget(self, action: #selector(startTalk(sender:)), for: .touchDown)
        button.addTarget(self, action: #selector(stopTalk(sender:)), for: .touchCancel)
        button.addTarget(self, action: #selector(stopTalk(sender:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(stopTalk(sender:)), for: .touchUpOutside)
        return button
    }()
    lazy private var bottomLabel: UILabel = {
        let label = UILabel()
        label.text = "Long press the microphone button to record 15 seconds voice message. maxmum support 5 voices"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 12)
        label.textColor = .lightGray
        return label
    }()
    lazy private var limitLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "Already up to maximum limit, please delete a recored first"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14)
        label.layer.cornerRadius = 16
        label.textColor = .lightGray
        label.layer.backgroundColor = UIColor.yellow.cgColor
        return label
    }()
    // MARK: - 按钮事件
    public func limitTalk() {
        limitLabel.isHidden = false
        topLabel.isHidden = true
        animationView.isHidden = true
        let text = "Long press the microphone button to record 15 seconds voice message. maxnum support 5 voices"
        bottomLabel.text = text
        bottomLabel.textColor = .lightGray
        bottomLabel.font = .systemFont(ofSize: 12)
        self.bringSubviewToFront(limitLabel)
    }
    @objc private func startTalk(sender: UIButton) {
        currentTime = 0
        topLabel.text = "00:00"
        limitLabel.isHidden = true
        topLabel.isHidden = false
        animationView.isHidden = false
        bottomLabel.text = "Recording..."
        bottomLabel.textColor = .blue
        bottomLabel.font = .systemFont(ofSize: 16)
        guard let talk = self.startTalk else {
            return
        }
        talk()
        let select = #selector(cumulativeTime)
        voiceTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: select, userInfo: nil, repeats: true)
    }
    @objc private func stopTalk(sender: UIButton) {
        limitLabel.isHidden = true
        topLabel.isHidden = true
        animationView.isHidden = true
        let text = "Long press the microphone button to record 15 seconds voice message. maxmum support 5 voices"
        bottomLabel.text = text
        bottomLabel.textColor = .lightGray
        bottomLabel.font = .systemFont(ofSize: 12)
        guard let talk = self.stopTalk else {
            return
        }
        let voice = RecordVoice()
        voice.path = voicePath
        voice.time = timerString
        talk(voice)
        stopRecordVoice()
        currentTime = 0
        voiceTimer?.invalidate()
    }
    public func startTalkClicked(startTalk: @escaping (() -> Void)) {
        self.startTalk = startTalk
    }
    public func stopTalkkClicked(stopTalk: @escaping ((RecordVoice) -> Void)) {
        self.stopTalk = stopTalk
    }

    // MARK: - 初始化录音
    private func initializeRecord() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSession.Category.playAndRecord)
            try session.overrideOutputAudioPort(.speaker)
        } catch let err {
            print(err.localizedDescription)
        }
        do {
            try session.setActive(true)
        } catch let err {
            print(err.localizedDescription)
        }
        voicePath = RecordFileManager.path(fileName: "/record" + musicMode)
        recorderSeting = [
            AVSampleRateKey: NSNumber(value: 16000),
            AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC),
            AVLinearPCMBitDepthKey: NSNumber(value: 16),
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
        ]
    }
    // MARK: - 开始录制声音
    func startRecordVoice() {
        do {
            guard let filePath = voicePath else {
                return
            }
            let url = URL(fileURLWithPath: filePath)
            guard let settings = self.recorderSeting else {
                return
            }
            recorder = try AVAudioRecorder(url: url, settings: settings)
            guard let recorder = self.recorder else {
                return
            }
            recorder.prepareToRecord()
            recorder.record()
        } catch let err {
            print(err.localizedDescription)
        }
    }
    // MARK: - 停止录制声音
    func stopRecordVoice() {
        recorder?.stop()
        recorder = nil    }
    // MARK: - 累积时间
    @objc func cumulativeTime() {
        currentTime += 1
        let minute = currentTime / 60 % 60
        let second = currentTime % 60
        timerString = NSString(format: "%02d:%02d", minute, second) as String
        self.topLabel.text = timerString
    }

    // MARK: - 布局子控件
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutSubview()
    }
    private func layoutSubview() {
        topLabel.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(50)
        }
        animationView.snp.makeConstraints { make in
            make.top.equalTo(topLabel.snp.bottom)
            make.height.equalTo(85)
            make.width.equalTo(160)
            make.centerX.equalTo(self)
        }
        limitLabel.snp.makeConstraints { make in
            make.top.equalTo(self).offset(20)
            make.height.equalTo(60)
            make.width.equalTo(288)
            make.centerX.equalTo(self)
        }
        talkButton.snp.makeConstraints { make in
            make.top.equalTo(animationView.snp.bottom)
            make.height.equalTo(50)
            make.width.equalTo(85)
            make.centerX.equalTo(self)
        }
        bottomLabel.snp.makeConstraints { make in
            make.top.equalTo(talkButton.snp.bottom)
            make.bottom.equalTo(self)
            make.left.equalTo(16)
            make.right.equalTo(-16)
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
