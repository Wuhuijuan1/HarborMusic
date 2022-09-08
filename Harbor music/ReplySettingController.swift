//
//  DoorbellReplySettingController.swift
//  SmartCam View
//
//  Created by YangGuiWen on 2022/3/14.
//

import UIKit
import RxSwift
import AVFoundation
import RxCocoa

class ReplySettingController: UIViewController, UITableViewDelegate, AVAudioPlayerDelegate {
    private var viewModel = ReplySettingModel()
    private var voice = RecordVoice()
    private var selectedIndex = 0
    private let recorder = VoiceRecorder()
    private let player = VoicePlayer()
    private var textField = UITextField()
    private var voiceDataSubject = BehaviorSubject(value: [RecordVoice()])
    private let disposeBag = DisposeBag()
    private var playDisposeBag = DisposeBag()
    // MARK: - 初始化
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Quick Reply Setting"
        self.view.backgroundColor = .white
        view.addSubview(listView)
        view.addSubview(recorder)
        view.addSubview(pickerView)
        bindObservable()
        observaRecordAndPlay()
    }
    func observaRecordAndPlay() {
        recorder.startTalkClicked { [weak self] in
            guard let self = self else { return }
            if self.viewModel.voiceArray.count < 100 {
                self.createVoice()
            } else {
                self.recorder.limitTalk()
            }
        }
        recorder.stopTalkkClicked { [weak self] voice in
            guard let self = self, voice.time != nil else {
                AlertView()
                    .add(title: "title")
                    .add(message: "时间太短了")
                    .add(action: "Cancel", clicked: { _, _, _ in
                    }, with: nil)
                    .show()
                return
            }
            self.voice = voice
            guard self.viewModel.voiceArray.count < 100 else { return }
            self.confirmVoice()
        }
        
    }
    // MARK: - 绑定数据
    private func bindObservable() {
        let observer = voiceDataSubject.asObserver()
        let cellType = ReplySettingCell.self
        observer.bind(
            to: listView.rx.items(
            cellIdentifier: "ID",
            cellType: cellType)) { [weak self] index, voice, cell in
            guard let self = self else { return }
                if let path = voice.path {
                    let url = URL(fileURLWithPath: path)
                    let videoAsset = AVAsset(url: url)
                    let track = videoAsset.tracks(withMediaType: .audio).first
                    let timeInterval = Int(track?.timeRange.duration.seconds ?? 0.0)
                    let seconds = timeInterval % 60
                    let minutes = timeInterval / 60
                    let str = String(format: "%02d:%02d", minutes, seconds)
                    cell.timeLabel.text = str
                }
                
            cell.playButton.isSelected = voice.isPlay
            cell.voiceNameLabel.text = voice.name
            cell.editClicked { [weak self] in
                guard let self = self else { return }
                self.editVoice(index: index)
            }
            cell.deleteClicked { [weak self] in
                guard let self = self else { return }
                self.deleteVoice(index: index)
            }
            cell.playClicked { [weak self] in
                guard let self = self else { return }
                self.playVoice(index: index)
            }
            cell.shareClicked { [weak self] in
                guard let self = self else { return }
                self.popToShareVC(index: index)
            }
        } 
        .disposed(by: disposeBag)
        voiceDataSubject.onNext(viewModel.voiceArray)
    }
    // MARK: - 编辑
    private func editVoice(index: Int) {
        self.textField.text = ""
        AlertView()
            .add(title: "Record Name")
            .add(customView: self.textFieldView)
            .add(action: "Cancel", clicked: { _, _, _ in
                print("cancel")
            }, with: nil)
            .add(action: "Confirm", clicked: { [weak self] _, _, _ in
                guard let self = self else { return }
                self.voice = self.viewModel.voiceArray[index]
                guard let name = self.textField.text else { return }
                let isSuccess = self.viewModel.editVoice(voice: self.voice, name: name)
                if isSuccess {
                    self.voice.name = name
                    self.viewModel.voiceArray[index] = self.voice
                    self.voiceDataSubject.onNext(self.viewModel.voiceArray)
                }
            }, with: nil)
            .show()
    }
    // MARK: - 删除
    private func deleteVoice(index: Int) {
        AlertView()
            .add(title: "Record Name")
            .add(message: " 确定要删除这条消息吗？")
            .add(action: "Cancel", clicked: { _, _, _ in
                print("cancel")
            }, with: nil)
            .add(action: "Confirm", clicked: { [weak self] _, _, _ in
                guard let self = self else { return }
                self.voice = self.viewModel.voiceArray[index]
                let isSuccess = self.viewModel.deleteVoice(voice: self.voice)
                if  isSuccess {
                    self.viewModel.voiceArray.remove(at: index)
                    self.voiceDataSubject.onNext(self.viewModel.voiceArray)
                }
            }, with: nil)
            .show()
    }
    // MARK: - 播放
    private func playVoice(index: Int) {
        playDisposeBag = DisposeBag()
        self.voice = viewModel.voiceArray[index]
        guard let playPath = voice.path else { return }
        if self.selectedIndex == index {
            if self.voice.isPlay {
                player.stopPlayVoice()
                voice.isPlay = false
            } else {
                player.startPlayVoice(path: playPath)
                voice.isPlay = true
            }
        } else {
            self.selectedIndex = index
            viewModel.voiceArray.forEach { voice in
                voice.isPlay = false
            }
            player.stopPlayVoice()

            self.voice.isPlay = true
            viewModel.voiceArray[index] = self.voice
            player.startPlayVoice(path: playPath)
        }
        let cell = self.listView.cellForRow(at: IndexPath(row: index, section: 0)) as? ReplySettingCell
        let model = self.viewModel.voiceArray[index]
        player.playDidFinishedSubject.subscribe { [weak self] _ in
            guard let self = self else { return }
            cell?.playButton.isSelected = false
            model.isPlay = false
            self.listView.reloadData()
        }
        .disposed(by: playDisposeBag)
        self.voiceDataSubject.onNext(self.viewModel.voiceArray)
    }
    private func createVoice() {
        recorder.startRecordVoice()
    }
    private func confirmVoice() {
        player.voicePath = self.voice.path
        self.textField.text = ""
        AlertView()
            .add(title: "New Voice Message")
            .add(customView: self.player)
            .add(action: "Delete") { [weak self] _, _, _ in
                guard let self = self else { return }
                self.player.stopPlayVoice()
            }
            .add(action: "Save", clicked: { [weak self] _, _, _ in
                guard let self = self else { return }
                self.player.stopPlayVoice()
                AlertView()
                    .add(title: "Record Name")
                    .add(customView: self.textFieldView)
                    .add(action: "Cancel", clicked: { _, _, _ in
                        print("cancel")
                    }, with: nil)
                    .add(action: "Confirm", clicked: { [weak self] _, _, _ in
                        guard let self = self, let name = self.textField.text else { return }
                        if name.count < 1 {
                            AlertView()
                                .add(title: "title")
                                .add(message: "不能为空")
                                .add(action: "OK", clicked: { _, _, _ in
                                }, with: nil)
                                .show()
                        } else {
                            self.voice.name = name
                            self.viewModel.saveVoice(voice: self.voice)
                            self.voiceDataSubject.onNext(self.viewModel.voiceArray)
                        }
                    }, with: nil)
                    .show()
            }, with: nil)
            .show()
    }
    // MARK: - 创建子控件
    lazy private var listView: UITableView = {
        let tableView = UITableView()
        let nibName = "DoorbellReplySettingCell"
        tableView.register(UINib.init(nibName: nibName, bundle: Bundle.main), forCellReuseIdentifier: "ID")
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        return tableView
    }()
    lazy private var textFieldView: UIView = {
        let view = UIView()
        let textField = textField
        textField.placeholder = "Please Enter a Name"
        textField.textColor = .lightGray
        let line = UIView()
        line.backgroundColor = .lightGray
        view.addSubview(textField)
        textField.snp.makeConstraints { make in
            make.leading.equalTo(view).offset(16)
            make.trailing.equalTo(view).offset(-16)
            make.centerY.equalTo(view)
            make.height.equalTo(44)
        }
        view.addSubview(line)
        line.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.leading.equalTo(view).offset(16)
            make.trailing.equalTo(view).offset(-16)
            make.top.equalTo(textField.snp.bottom)
            make.bottom.equalTo(view)
        }
        return view
    }()
    private lazy var pickerView: UIView = {
        let pickerView = UIView()
        pickerLabel.text = "Music Mode: "
        pickerLabel.font = .systemFont(ofSize: 20)
        modePicker.delegate = self
        modePicker.dataSource = self
        pickerView.addSubview(pickerLabel)
        pickerView.addSubview(modePicker)
        return pickerView
    }()
    private let pickerLabel = UILabel()
    private let modePicker = UIPickerView()
    private let pickerDataSource = [".aac", ".mov", ".mp4", ".m4v", ".3gp", ".avi"]
    // MARK: - 布局子控件
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutSubview()
    }
    private func layoutSubview() {
        listView.snp.makeConstraints { make in
            make.top.left.right.equalTo(view)
            make.height.equalTo(300)
        }
        recorder.snp.makeConstraints { make in
            make.top.equalTo(pickerView.snp.bottom).offset(5)
            make.bottom.equalTo(view)
            make.right.left.equalTo(view)
        }
        pickerLabel.snp.makeConstraints { make in
            make.centerY.leading.equalToSuperview()
        }
        modePicker.snp.makeConstraints { make in
            make.leading.equalTo(pickerLabel.snp.trailing)
            make.top.bottom.trailing.equalToSuperview()
            make.height.equalTo(56)
            make.width.equalTo(150)
        }
        pickerView.snp.makeConstraints { make in
            make.top.equalTo(listView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
        
    }
}

extension ReplySettingController {
    func popToShareVC(index: Int) {
        let rect = CGRect(x: view.bounds.width * 0.5, y: view.bounds.height - 78, width: 0, height: 0)
        let voice = viewModel.voiceArray[index]
        guard let path = voice.path else { return }
        let url = URL(fileURLWithPath: path)
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view;
        activityVC.popoverPresentationController?.sourceRect = rect;
        activityVC.popoverPresentationController?.permittedArrowDirections = .down;
        activityVC.popoverPresentationController?.backgroundColor = .lightGray
        self.present(activityVC, animated: true)
    }
}

extension ReplySettingController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerDataSource[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.viewModel.musicMode = pickerDataSource[row]
        self.recorder.musicMode = pickerDataSource[row]
    }
}
