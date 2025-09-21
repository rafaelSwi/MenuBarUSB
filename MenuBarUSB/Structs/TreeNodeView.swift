//
//  TreeNodeView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth Swierczynski on 21/09/25.
//

import SwiftUI

struct TreeNodeView: View {
    
    let deviceId: String
    let level: Int
    let inheritedDevices: [HeritageDevice]
    let manager: USBDeviceManager
    let renamedDevices: [RenamedDevice]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Rectangle()
                    .frame(width: CGFloat(level) * 10, height: 1)
                    .opacity(level > 0 ? 0.5 : 0)
                
                if let device = manager.devices.first(where: { USBDevice.uniqueId($0) == deviceId }) {
                    Text(renamedDevices.first(where: { $0.deviceId == deviceId })?.name ?? device.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                } else {
                    Text("(\(String(localized: "no_info")))")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            
            // Filhos
            let children = inheritedDevices
                .filter { $0.inheritsFrom == deviceId }
                .map { $0.deviceId }
            
            ForEach(children, id: \.self) { childId in
                TreeNodeView(
                    deviceId: childId,
                    level: level + 1,
                    inheritedDevices: inheritedDevices,
                    manager: manager,
                    renamedDevices: renamedDevices
                )
            }
        }
    }
}
