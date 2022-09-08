//
//  DoorbellReplySettingModel.swift
//  SmartCam View
//
//  Created by YangGuiWen on 2022/3/15.
//

import UIKit
class ReplySettingModel: NSObject {
    public var musicMode = ".aac"
    public var voicePath: String?
    public var voiceArray: [RecordVoice] = []
    override init() {
        super.init()
        initVoice()
    }
    // MARK: - 编辑声音
    func editVoice(voice: RecordVoice, name: String) -> Bool {
        let filePath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask,
            true).first?.appending("/RecordFile")
        guard let path = filePath else { return false }
        guard let voicePath = voice.path else { return false }
        let originalPath = voicePath
        let suffix = voicePath.components(separatedBy: ".").last ?? ""
        let newPath = path.appending("/\(name)." + suffix)
        let url = URL(fileURLWithPath: originalPath)
        let fileManager = FileManager.default
        do {
            try fileManager.moveItem(at: url, to: URL(fileURLWithPath: newPath))
            voice.path = newPath
            return true
        } catch let err {
            print(err.localizedDescription)
            return false
        }
    }
    // MARK: - 删除声音
    func deleteVoice(voice: RecordVoice) -> Bool {
        let voice = voice
        let filePath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask,
            true).first?.appending("/RecordFile")
        let fileManager = FileManager.default
        guard let pathOk = filePath else { return false }
        guard let string = voice.name else { return false }
        do {
            let suffix = voice.path?.components(separatedBy: ".").last ?? ""
            if fileManager.fileExists(atPath: pathOk + "/\(string)." + suffix) {
                try fileManager.removeItem(atPath: pathOk + "/\(string)." + suffix)
            }
            return true
        } catch let err {
            print(err.localizedDescription)
            return false
        }
    }
    // MARK: - 保存声音
    func saveVoice(voice: RecordVoice) {
        let filePath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask,
            true).first?.appending("/RecordFile")
        let fileManager = FileManager.default
        guard let pathOk = filePath else { return }
        if !fileManager.fileExists(atPath: pathOk) {
            do {
                try fileManager.createDirectory(atPath: pathOk, withIntermediateDirectories: true, attributes: nil)
            } catch let err {
                print(err.localizedDescription)
            }
        }
        do {
            guard let string = voice.name else { return }
            if fileManager.fileExists(atPath: pathOk + "/\(string)" + self.musicMode) {
                try fileManager.removeItem(atPath: pathOk + "/\(string)" + self.musicMode)
            }
            guard let pathOk = filePath else { return }
            guard let path = voice.path else { return }
            try fileManager.copyItem(atPath: path, toPath: pathOk + "/\(string)" + self.musicMode)
            voice.path = pathOk + "/\(string)" + self.musicMode
            voice.isPlay = false
        } catch let err {
            print(err.localizedDescription)
        }
        self.voiceArray.append(voice)
    }
    
    func initVoice() {
        let files = RecordFileManager.allMusicFiles()
        let fileManager = FileManager.default
        guard let pathOK = RecordFileManager.path(fileName: "RecordFile") else { return }
        files.forEach { [weak self] fileName in
            guard let self = self else { return }
            let path = pathOK + "/\(fileName)"
            let name = fileName.components(separatedBy: ".").first
            guard let name = name, fileManager.fileExists(atPath: path) else {
                return
            }
            let voice = RecordVoice.init(name: name, time: "0", path: path, play: false)
            self.voiceArray.append(voice)
        }
    }
}

class RecordVoice {
    public var name: String?
    public var time: String?
    public var path: String?
    public var isPlay = false
    init() {
        self.name = String()
        self.time = String()
        self.path = String()
        self.isPlay = Bool()
    }
    init(name: String, time: String, path: String, play: Bool) {
        self.name = name
        self.time = time
        self.path = path
        self.isPlay = play
    }
}
