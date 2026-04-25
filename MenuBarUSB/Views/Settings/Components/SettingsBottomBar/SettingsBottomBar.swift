//
//  SettingsBottomBar.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct SettingsBottomBar: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    
    @Binding var currentWindow: AppWindow
    @Binding var resetSettingsPress: Int
    
    @AS(Key.settingsCategory) private var category: SettingsCategory = .system
    @AS(Key.internetMonitoring) private var internetMonitoring = false
    
    private var isTrafficMonitoringPausedForSettings: Bool {
        return internetMonitoring && !manager.trafficMonitorRunning && manager.ethernetCableConnected
    }
    
    private func resetAppSettings() {
        Utils.App.deleteStorageData()
        resetSettingsPress = 0
        Utils.System.playSound("Bottle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            Utils.App.restart()
        }
    }
    
    var body: some View {
        HStack {
            if category == .storage {
                Button("restore_default_settings") {
                    resetSettingsPress += 1
                    if resetSettingsPress == 5 {
                        resetAppSettings()
                    }
                }
                
                if resetSettingsPress > 0 {
                    Text("(\(resetSettingsPress)/5)")
                        .font(.footnote)
                }
            }
            
            Spacer()
            
            Button(action: {
                if isTrafficMonitoringPausedForSettings {
                    manager.startEthernetMonitoring()
                }
                currentWindow = .devices
            }) {
                if isTrafficMonitoringPausedForSettings {
                    Label("back_and_resume", systemImage: "arrow.uturn.backward")
                        .contextMenu {
                            SettingsBottomBarContextMenuExitTraffic(currentWindow: $currentWindow)
                        }
                } else {
                    Label("back", systemImage: "arrow.uturn.backward")
                }
            }
        }
    }
}
