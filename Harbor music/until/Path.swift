//
//  Path.swift
//  Harbor music
//
//  Created by Wuhuijuan on 2022/9/2.
//

import Foundation

class Path {
    static func filePath(filename: String) -> String {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first?.appending("/\(filename)");
        guard let path = path else { fatalError() }
        return path
    }
}
