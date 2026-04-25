//
//  MainListDeviceListContextMenuOfflineDevice.swift
//  MenuBarUSB
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct MainListDeviceListContextMenuOfflineDevice: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    
    @Binding var inputText: String
    @Binding var isRenamingDeviceId: String
    
    let storedDevice: StoredDevice
    
    private func showRestoreName(for deviceId: String) -> Bool {
        let renamed = CSM.Renamed.devices.first { $0.deviceId == deviceId }
        return renamed != nil
    }
    
    var body: some View {
        Button {
            manager.refresh()
        } label: {
            Label("refresh", systemImage: "arrow.clockwise")
        }
        Divider()
        Button {
            CSM.Camouflaged.add(withId: storedDevice.deviceId)
            manager.refresh()
        } label: {
            Label("hide", systemImage: "eye.slash")
        }
        Button {
            inputText = ""
            isRenamingDeviceId = storedDevice.deviceId
        } label: {
            Label("rename", systemImage: "pencil.and.scribble")
        }
        if showRestoreName(for: storedDevice.deviceId) {
            Button {
                CSM.Renamed.remove(withId: storedDevice.deviceId)
            } label: {
                Label("restore_name", systemImage: "eraser.line.dashed")
            }
        }
        Divider()
        Button {
            CSM.Stored.remove(withId: storedDevice.deviceId)
            manager.refresh()
        } label: {
            Label("remove_from_history", systemImage: "trash")
        }
    }
}
