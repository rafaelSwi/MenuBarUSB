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
        set userName to short user name of (system info)
        set hostName to computer name of (system info)
        
        set filePath to (path to desktop folder as text) & "menuBarUSB_test.txt"
        
        set fileRef to open for access file filePath with write permission
        write ("User: " & userName & linefeed & "Mac: " & hostName & linefeed & "Test OK") to fileRef
        close access fileRef
        
        tell application "Finder"
            activate
            open desktop
            select file "menuBarUSB_test.txt" of desktop
        end tell
        
        display dialog "file created" buttons {"OK"} default button "OK"
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
