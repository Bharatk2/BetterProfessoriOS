//
//  Log.swift
//  BetterProfessor
//
//  Created by Bharat Kumar on 12/26/20.
//  Copyright © 2020 Bhawnish Kumar. All rights reserved.
//

import Foundation

public class Log {
    static let debug = true

    static func wth(_ TAG: String?, _ MSG: Any) {
        print("\(TAG!) : \(MSG)")
    }

    static func data(_ TAG: String?, _ data: Data) {
        let str = String(data: data, encoding: .utf8)
        wth(TAG, str)
    }
}
