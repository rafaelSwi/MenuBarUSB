//
//  USBDeviceWrapper.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 10/10/25.
//

import Foundation

final class USBDeviceWrapper: Identifiable, Equatable, Hashable {
    let id = UUID()
    var item: USBDevice

    init(_ item: consuming USBDevice) {
        self.item = item
    }

    static func == (lhs: USBDeviceWrapper, rhs: USBDeviceWrapper) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
