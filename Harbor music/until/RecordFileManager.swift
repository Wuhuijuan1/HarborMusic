//
//  FileManager.swift
//  Harbor music
//
//  Created by Wuhuijuan on 2022/9/6.
//

import Foundation

class RecordFileManager {
    static func path(fileName: String) -> String? {
        return NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask,
            true).first?.appending("/\(fileName)")
    }
    
    static func allMusicFiles() -> [String] {
        let manager = FileManager.default
        guard let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask,
            true).first?.appending("/RecordFile") else { return [] }
        let files = try? manager.contentsOfDirectory(atPath: path)
        return files ?? []
    }
}
