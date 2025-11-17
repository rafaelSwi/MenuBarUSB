//
//  USBDevice.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import Foundation

struct USBDevice: ~Copyable {
    let id = UUID()
    let name: String
    let vendor: String?
    let vendorId: Int
    let productId: Int
    let serialNumber: String?
    let locationId: UInt32?
    let speedMbps: Int?
    let portMaxSpeedMbps: Int?
    let usbVersionBCD: Int?
    let isExternalStorage: Bool?

    var uniqueId: String {
        return "\(vendorId)-\(productId)-\(String(describing: locationId))"
    }

    var speedDescription: String {
        guard let devMbps = speedMbps else {
            return "unknown_speed".localized
        }
        var parts: [String] = [Utils.USB.speedTierLabel(for: devMbps)]

        if let port = portMaxSpeedMbps {
            if devMbps < port {
                parts.append("— \("supports_up_to".localized) \(Utils.USB.prettyMbps(port))")
            } else {
                parts.append("— \("supports".localized) \(Utils.USB.prettyMbps(port))")
            }
        }
        return parts.joined(separator: " ")
    }
}
