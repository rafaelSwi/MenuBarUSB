//
//  LegacySettingsStorageCategory.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct LegacySettingsStorageCategory: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    
    @State private var tryingToResetSettings = false
    @Binding var showOthersOptions: Bool
    
    var body: some View {
        
        StorageButton(type: .pinned) {
            CSM.Pin.clear()
            manager.refresh()
        }
        
        StorageButton(type: .renamed) {
            CSM.Renamed.clear()
            manager.refresh()
        }
        
        StorageButton(type: .camouflaged) {
            CSM.Camouflaged.clear()
            manager.refresh()
        }
        
        StorageButton(type: .heritage) {
            CSM.Heritage.clear()
            manager.refresh()
        }
        
        StorageButton(type: .soundAssociation) {
            CSM.SoundDevices.clear()
            manager.refresh()
        }
        
        StorageButton(type: .sound) {
            CSM.Sound.clear()
            manager.refresh()
        }
        
        StorageButton(type: .stored) {
            CSM.Stored.clear()
            manager.refresh()
        }
        
        StorageButton(type: .log) {
            CSM.ConnectionLog.clear()
            manager.refresh()
        }
        
        Spacer()
            .frame(height: 8)
        
        HStack {
            
            Button("restore_default_settings") {
                tryingToResetSettings = true
            }
            .disabled(tryingToResetSettings)
            
            if tryingToResetSettings {
                HStack(spacing: 12) {
                    Text("are_you_sure")
                        .bold()
                        .foregroundStyle(.red)
                    Button("no") {
                        tryingToResetSettings = false
                    }
                    Button("yes_confirm") {
                        Utils.App.deleteStorageData()
                        tryingToResetSettings = false
                        showOthersOptions = false
                        Utils.System.playSound("Bottle")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            Utils.App.restart()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}
