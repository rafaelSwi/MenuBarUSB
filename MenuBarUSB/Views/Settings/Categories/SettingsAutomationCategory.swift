//
//  SettingsAutomationCategory.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

// THIS IS UNDER TESTING
// It may or may not end up being a feature.

import SwiftUI

struct SettingsAutomationCategory: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    
    @Binding var activeRowID: UUID?
    
    func runTestScript() {
        let scriptSource = """
        """
        
        if let script = NSAppleScript(source: scriptSource) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
            
            if let error = error {
                print("Error: \(error)")
            } else {
                print("Script executed")
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            
            Button("Run Script") {
                runTestScript()
            }
            
        }
    }
}
