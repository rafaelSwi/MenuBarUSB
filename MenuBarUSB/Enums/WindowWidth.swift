//
//  WindowWidth.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 13/11/25.
//

import CoreFoundation

enum WindowWidth: Int {
    case tiny = 410
    case normal = 465
    case big = 510
    case veryBig = 560
    case huge = 620

    static var value: CGFloat {
        @AS(Key.windowWidth) var number: WindowWidth = .normal
        return CGFloat(number.rawValue)
    }
}
