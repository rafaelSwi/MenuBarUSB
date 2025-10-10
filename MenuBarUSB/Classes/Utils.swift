//
//  Utils.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 02/10/25.
//

import Foundation
import AppKit

final class Utils {
    
    static func killApp() {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-n", Bundle.main.bundlePath]
        task.launch()
        NSApp.terminate(nil)
    }
    
    static func openSysInfo() {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [
            "-b", "com.apple.SystemProfiler",
            "--args", "SPUSBDataType"
        ]
        try? task.run()
    }
    
    static func hapticFeedback() {
        let performer = NSHapticFeedbackManager.defaultPerformer
        performer.perform(.generic, performanceTime: .now)
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
    
}
