//
//  LogsContextMenuSingleLog.swift
//  MenuBarUSB
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct LogsContextMenuSingleLog: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    
    @Binding var paintedLogs: [String]
    @Binding var blacklistedIds: [String]
    var log: DeviceConnectionLog
    var isPainted: Bool
    
    var body: some View {
        Button(isPainted ? "remove_paint" : "paint") {
            if !isPainted { paintedLogs.append(log.id) }
            else { paintedLogs.removeAll(where: { $0 == log.id }) }
            manager.refresh()
        }
        
        Divider()
        
        Button("temporarily_ignore_device_logs") {
            blacklistedIds.append(log.deviceId)
        }
    }
}
