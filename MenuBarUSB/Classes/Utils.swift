//
//  Utils.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 02/10/25.
//

import AppKit
import Foundation
import SwiftUI
import UserNotifications

final class Utils {
    final class System {
        static func openSysInfo() {
            let task = Process()
            task.launchPath = "/usr/bin/open"
            task.arguments = [
                "-b", "com.apple.SystemProfiler",
                "--args", "SPUSBDataType",
            ]
            try? task.run()
        }

        static func copyToClipboard(_ content: String) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(content, forType: .string)
        }

        static func hapticFeedback() {
            @AS(Key.disableHaptic) var disableHaptic = false
            if disableHaptic { return }
            let performer = NSHapticFeedbackManager.defaultPerformer
            performer.perform(.generic, performanceTime: .now)
        }

        static func playSound(_ sound: String?, limit: TimeInterval = 8) {
            guard let sound = sound else { return }

            var audio: NSSound? = nil

            if let systemSound = NSSound(named: NSSound.Name(sound)) {
                audio = systemSound
            } else if let url = Bundle.main.url(forResource: sound, withExtension: "mp3"),
                      let mp3Sound = NSSound(contentsOf: url, byReference: false)
            {
                audio = mp3Sound
            } else {
                let fileURL = URL(fileURLWithPath: sound)
                if FileManager.default.fileExists(atPath: fileURL.path),
                   let fileSound = NSSound(contentsOf: fileURL, byReference: true)
                {
                    audio = fileSound
                }
            }

            guard let audio else { return }

            audio.play()
            let stopTime = min(limit, audio.duration)

            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + stopTime) {
                audio.stop()
            }
        }

        static var isMacbook: Bool {
            var size = 0

            if sysctlbyname("hw.model", nil, &size, nil, 0) != 0 {
                return false
            }

            var model = [CChar](repeating: 0, count: size)
            if sysctlbyname("hw.model", &model, &size, nil, 0) != 0 {
                return false
            }

            let identifier = String(cString: model)
            let lower = identifier.lowercased()

            let desktopPrefixes = ["imac", "macmini", "macstudio", "macpro"]

            if desktopPrefixes.contains(where: { lower.hasPrefix($0) }) {
                return false
            }

            return lower.hasPrefix("mac")
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
            DispatchQueue.global(qos: .utility).async {
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
    }

    final class App {
        static var appVersion: String {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
        }

        static func hasUpdate() async -> Bool {
            guard let url = URL(string: "https://api.github.com/repos/rafaelSwi/MenuBarUSB/releases/latest") else { return false }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                let latest = release.tag_name.replacingOccurrences(of: "v", with: "")
                return Utils.App.isVersion(Utils.App.appVersion, olderThan: latest)
            } catch {
                return false
            }
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

        static func deleteFromAppStorage(_ pathOrFilename: String) {
            let fileManager = FileManager.default
            let inputURL = URL(fileURLWithPath: pathOrFilename)

            if inputURL.path.hasPrefix("/") {
                if fileManager.fileExists(atPath: inputURL.path) {
                    do {
                        try fileManager.removeItem(at: inputURL)
                        print("File removed (absolute path): \(inputURL.path)")
                    } catch {
                        print("Error removing absolute file: \(error)")
                    }
                } else {
                    print("Absolute file not found: \(inputURL.path)")
                }
                return
            }

            guard let appSupport = try? fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            ) else {
                print("Could not access Application Support directory.")
                return
            }

            let fileURL = appSupport.appendingPathComponent(pathOrFilename)

            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    try fileManager.removeItem(at: fileURL)
                    print("File removed (app storage): \(fileURL.path)")
                } catch {
                    print("Error removing file from app storage: \(error)")
                }
            } else {
                print("File not found in app storage: \(fileURL.path)")
            }
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

    final class USB {
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
                        format: "USB %@ (\("unknown".localized))",
                        versionString
                    )
                } else {
                    return String(
                        format: "\("unknown".localized) (0x%04X)",
                        bcd
                    )
                }
            }
        }

        static func speedTierLabel(for mbps: Int) -> String {
            switch mbps {
            case 1, 2: return "USB 1.0 \("low_speed".localized) (1.5 Mbps)"
            case 12: return "USB 1.1 \("full_speed".localized) (12 Mbps)"
            case 480: return "USB 2.0 \("high_speed".localized) (480 Mbps)"
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

    final class Miscellaneous {
        static let contactEmail = "contatorafaelswi@gmail.com"
        static let githubUrl = "https://github.com/rafaelSwi/MenuBarUSB"
        static let linkedinUrl = "https://www.linkedin.com/in/rafaelneuwirth/"
        static let linkedinProfile = "in/rafaelneuwirth"
        static let btcAddress = "bc1qvluxh224489mt6svp23kr0u8y2upn009pa546t"
        static let ltcAddress = "ltc1qz42uw4plam83f2sud2rckzewvdwm9vs4rfazl5"

        static func generateQRCode(from string: String) -> NSImage? {
            let context = CIContext()
            let filter = CIFilter.qrCodeGenerator()
            filter.message = Data(string.utf8)

            guard let outputImage = filter.outputImage else { return nil }

            let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 12, y: 12))

            if let cgimg = context.createCGImage(scaled, from: scaled.extent) {
                return NSImage(cgImage: cgimg, size: NSSize(width: 300, height: 300))
            }
            return nil
        }

        struct QRCodeView: View {
            let text: String
            @State private var hovered = false

            var body: some View {
                let blurAmount: CGFloat = hovered ? 0 : (hovered ? 0 : 6)

                Group {
                    if let image = generateQRCode(from: text) {
                        Image(nsImage: image)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .blur(radius: blurAmount)
                            .animation(.easeInOut(duration: 0.5), value: blurAmount)
                            .onHover { hovering in
                                if hovering {
                                    hovered = true
                                }
                            }
                    } else {
                        Color.gray
                    }
                }
            }
        }
    }
}
