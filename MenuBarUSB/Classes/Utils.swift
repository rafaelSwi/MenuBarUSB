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
    
}
