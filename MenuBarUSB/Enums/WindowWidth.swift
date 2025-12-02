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
    case big = 500
    case veryBig = 545
    case huge = 605

    static var value: CGFloat {
        @AS(Key.windowWidth) var number: WindowWidth = .normal
        return CGFloat(number.rawValue)
    }
}
