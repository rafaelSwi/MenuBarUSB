//
//  SettingsContextMenuTrafficWarning.swift
//  MenuBarUSB
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct SettingsContextMenuTrafficWarning: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    @Binding var currentWindow: AppWindow
    
    var body: some View {
        Button {
            manager.startEthernetMonitoring()
            currentWindow = .devices
        } label: {
            Label("exit_settings_and_resume", systemImage: "arrow.uturn.backward")
        }
    }
}
