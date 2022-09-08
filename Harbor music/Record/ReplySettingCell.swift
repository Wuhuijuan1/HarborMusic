//
//  DoorbellReplySettingCell.swift
//  SmartCam View
//
//  Created by YangGuiWen on 2022/3/14.
//

import UIKit
import RxSwift

class ReplySettingCell: UITableViewCell {
    private var edit: (() -> Void)?
    private var delete: (() -> Void)?
    private var paly: (() -> Void)?
    private var share: (() -> Void)?
    private let disposeBag = DisposeBag()
    @IBOutlet weak var voiceNameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    // MARK: - 初始化
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = UITableViewCell.SelectionStyle.none
        setupSubview()
    }

    // MARK: - 设置子控件
    private func setupSubview() {
        // name
        voiceNameLabel.text = "Voice Name"
        voiceNameLabel.textColor = .black
        voiceNameLabel.font = .systemFont(ofSize: 16)
        // time
        timeLabel.text = "00:00"
        timeLabel.textColor = .black.withAlphaComponent(0.7)
        timeLabel.font = .systemFont(ofSize: 12)
        // edit
        editButton.setImage(UIImage(named: "lullaby_voice_edit"), for: .normal)
        editButton.rx.tap.asObservable()
            .subscribe { [weak self] _ in
                guard let self = self, let clicked = self.edit else {
                    return
                }
                clicked()
            }
            .disposed(by: disposeBag)
        // delete
        deleteButton.setImage(UIImage(named: "lullaby_voice_delete"), for: .normal)
        deleteButton.rx.tap.asObservable()
            .subscribe { [weak self] _ in
                guard let self = self, let clicked = self.delete else {
                    return
                }
                clicked()
            }
            .disposed(by: disposeBag)
        // paly
        playButton.setImage(UIImage(named: "lullaby_play"), for: .normal)
        playButton.setImage(UIImage(named: "lullaby_audition_pause"), for: .selected)
        playButton.rx.tap.asObservable()
            .subscribe { [weak self] _ in
                // self.playButton.isSelected.toggle()
                guard let self = self, let clicked = self.paly else {
                    return
                }
                clicked()
            }
            .disposed(by: disposeBag)
    }
    // MARK: - 按钮响应事件
    public func editClicked(edit: @escaping (() -> Void)) {
        self.edit = edit
    }
    public func deleteClicked(delete: @escaping (() -> Void)) {
        self.delete = delete
    }
    public func playClicked(play: @escaping (() -> Void)) {
        self.paly = play
    }
    public func shareClicked(share: @escaping (() -> Void)) {
        self.share = share
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func shareButtonDidClicked() {
        if let share = share {
            share()
        }
    }
}
