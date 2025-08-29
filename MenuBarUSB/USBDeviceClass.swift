//
//  USBDevice.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import Foundation

struct USBDevice: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let vendor: String?
    let vendorId: Int
    let productId: Int
    let serialNumber: String?
    let locationId: UInt32?
    let speedMbps: Int?
    
    var speedDescription: String {
        guard let speed = speedMbps else {
            return String(localized: "unknown_speed")
        }
        
        switch speed {
        case 1:
            return "USB 1.0 (1.5 Mbps)"
        case 12:
            return "USB 1.1 (12 Mbps)"
        case 480:
            return "USB 2.0 (480 Mbps)"
        case 5000:
            return "USB 3.0 / 3.1 Gen1 (5 Gbps)"
        case 10000:
            return "USB 3.1 Gen2 (10 Gbps)"
        case 20000:
            return "USB 3.2 Gen2x2 (20 Gbps)"
        case 40000:
            return "USB4 (40 Gbps)"
        default:
            if speed >= 1000 {
                return String(format: "%.1f Gbps", Double(speed) / 1000.0)
            } else {
                return "\(speed) Mbps"
            }
        }
    }
}
