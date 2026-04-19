//
//  SettingsStorageCategory.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct SettingsStorageCategory: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
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
        }
    }
}
