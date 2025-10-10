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
    
    
    
    static func usbVersionLabel(from bcd: Int?, convertHexa: Bool) -> String? {
        guard let bcd = bcd else { return nil }
        switch bcd {
        case 0x0100: return "USB 1.0"
        case 0x0110: return "USB 1.1"
        case 0x0200: return "USB 2.0"
        case 0x0300: return "USB 3.0"
        case 0x0310: return "USB 3.1"
        case 0x0320: return "USB 3.2"
        case 0x0400: return "USB4"
        case 0x0420: return "USB4 2.0"
        default:
            let major = (bcd >> 8) & 0xFF
            let minorHigh = (bcd >> 4) & 0x0F
            let minorLow  = bcd & 0x0F
            let minor = minorHigh * 10 + minorLow

            let versionString = minor == 0 ? "\(major)" : "\(major).\(minor)"
            if (convertHexa) {
                return String(
                    format: "USB %@ (\(String(localized: "unknown")))",
                    versionString
                )
            } else {
                return String(
                    format: "\(String(localized: "unknown")) (0x%04X)",
                    bcd
                )
            }
            
        }
    }

    static func speedTierLabel(for mbps: Int) -> String {
        switch mbps {
        case 1, 2:       return "USB 1.0 \(String(localized: "low_speed")) (1.5 Mbps)"
        case 12:         return "USB 1.1 \(String(localized: "full_speed")) (12 Mbps)"
        case 480:        return "USB 2.0 \(String(localized: "high_speed")) (480 Mbps)"
        case 5000:       return "USB 3.0 / 3.1 Gen1 / 3.2 Gen1x1 (5 Gbps)"
        case 10000:      return "USB 3.1 Gen2 / 3.2 Gen2x1 (10 Gbps)"
        case 20000:      return "USB 3.2 Gen2x2 / USB4 Gen2x2 (20 Gbps)"
        case 40000:      return "USB4 Gen3x2 / Thunderbolt 3/4 (40 Gbps)"
        case 80000:      return "USB4 v2 Gen4x2 / Thunderbolt 5 (80 Gbps)"
        default:
            if mbps >= 1000 { return String(format: "%.1f Gbps", Double(mbps) / 1000.0) }
            return "\(mbps) Mbps"
        }
    }
    
    static func speedDescription(_ ptr: UnsafePointer<USBDevice>) -> String {
        guard let devMbps = ptr.pointee.speedMbps else {
            return String(localized: "unknown_speed")
        }
        var parts: [String] = [USBDevice.speedTierLabel(for: devMbps)]

        if let port = ptr.pointee.portMaxSpeedMbps {
            if devMbps < port {
                parts.append("— \(String(localized: "supports_up_to")) \(ptr.pointee.prettyMbps(port))")
            } else {
                parts.append("— \(String(localized: "supports")) \(ptr.pointee.prettyMbps(port))")
            }
        }
        return parts.joined(separator: " ")
    }

    private func prettyMbps(_ mbps: Int) -> String {
        mbps >= 1000 ? String(format: "%.1f Gbps", Double(mbps)/1000.0) : "\(mbps) Mbps"
    }
    
    static func uniqueId(_ ptr: UnsafePointer<USBDevice>) -> String {
        return "\(ptr.pointee.vendorId)-\(ptr.pointee.productId)-\(String(describing: ptr.pointee.locationId))";
    }

}
