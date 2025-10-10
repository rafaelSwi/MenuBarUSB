//
//  Utils.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 02/10/25.
//

import AppKit
import Foundation
import UserNotifications

enum Utils {
    enum System {
        static func openSysInfo() {
            let task = Process()
            task.launchPath = "/usr/bin/open"
            task.arguments = [
                "-b", "com.apple.SystemProfiler",
                "--args", "SPUSBDataType",
            ]
            try? task.run()
        }

        static func hapticFeedback() {
            let performer = NSHapticFeedbackManager.defaultPerformer
            performer.perform(.generic, performanceTime: .now)
        }

        static func playSound(_ sound: String) {
            if let sound = NSSound(named: NSSound.Name(sound)) {
                sound.play()
            }
        }

        static func requestNotificationPermission() {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                } else {
                    print("Notification permission granted? \(granted)")
                }
            }
        }

        static func sendNotification(title: String, body: String) {
            Utils.System.requestNotificationPermission()
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.interruptionLevel = .timeSensitive

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Failed to schedule notification: \(error.localizedDescription)")
                } else {
                    print("Notification scheduled.")
                }
            }
        }
    }

    class App {
        static var appVersion: String {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
        }

        static func exit() {
            NSApp.terminate(nil)
        }

        static func restart() {
            let task = Process()
            task.launchPath = "/usr/bin/open"
            task.arguments = ["-n", Bundle.main.bundlePath]
            task.launch()
            Utils.App.exit()
        }

        static func isVersion(_ v1: String, olderThan v2: String) -> Bool {
            let v1Components = v1.split(separator: ".").compactMap { Int($0) }
            let v2Components = v2.split(separator: ".").compactMap { Int($0) }
            for (a, b) in zip(v1Components, v2Components) {
                if a < b { return true }
                if a > b { return false }
            }
            return v1Components.count < v2Components.count
        }

        static func deleteStorageData() {
            let fileManager = FileManager.default

            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
                UserDefaults.standard.synchronize()
            }

            if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
               let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first,
               let bundleID = Bundle.main.bundleIdentifier
            {
                let appSupportPath = appSupport.appendingPathComponent(bundleID).path
                let cachesPath = caches.appendingPathComponent(bundleID).path

                try? fileManager.removeItem(atPath: appSupportPath)
                try? fileManager.removeItem(atPath: cachesPath)
            }
        }
    }

    class USB {
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
                let minorLow = bcd & 0x0F
                let minor = minorHigh * 10 + minorLow

                let versionString = minor == 0 ? "\(major)" : "\(major).\(minor)"
                if convertHexa {
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
            case 1, 2: return "USB 1.0 \(String(localized: "low_speed")) (1.5 Mbps)"
            case 12: return "USB 1.1 \(String(localized: "full_speed")) (12 Mbps)"
            case 480: return "USB 2.0 \(String(localized: "high_speed")) (480 Mbps)"
            case 5000: return "USB 3.0 / 3.1 Gen1 / 3.2 Gen1x1 (5 Gbps)"
            case 10000: return "USB 3.1 Gen2 / 3.2 Gen2x1 (10 Gbps)"
            case 20000: return "USB 3.2 Gen2x2 / USB4 Gen2x2 (20 Gbps)"
            case 40000: return "USB4 Gen3x2 / Thunderbolt 3/4 (40 Gbps)"
            case 80000: return "USB4 v2 Gen4x2 / Thunderbolt 5 (80 Gbps)"
            default:
                if mbps >= 1000 { return String(format: "%.1f Gbps", Double(mbps) / 1000.0) }
                return "\(mbps) Mbps"
            }
        }

        static func prettyMbps(_ mbps: Int) -> String {
            mbps >= 1000 ? String(format: "%.1f Gbps", Double(mbps) / 1000.0) : "\(mbps) Mbps"
        }
    }
}
