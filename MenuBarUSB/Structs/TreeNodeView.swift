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
    @Binding var inheritedDevices: [HeritageDevice]
    let manager: USBDeviceManager
    let renamedDevices: [RenamedDevice]
    
    private func removeInheritance(for deviceId: String) {
        inheritedDevices.removeAll { $0.deviceId == deviceId }
        
        let directChildren = inheritedDevices
            .filter { $0.inheritsFrom == deviceId }
            .map { $0.deviceId }
        
        for childId in directChildren {
            removeInheritance(for: childId)
        }
        
        inheritedDevices.removeAll { $0.inheritsFrom == deviceId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Rectangle()
                    .frame(width: CGFloat(level) * 10, height: 1)
                    .opacity(level > 0 ? 0.5 : 0)
                
                if let device = manager.deviceIDs.first(where: { USBDevice.uniqueId($0) == deviceId }) {
                    Text(renamedDevices.first(where: { $0.deviceId == deviceId })?.name ?? device.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                } else {
                    Text("(\(String(localized: "no_info")))")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                if level > 0 {
                    Button {
                        removeInheritance(for: deviceId)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .imageScale(.small)
                            .opacity(0.7)
                    }
                    .buttonStyle(.plain)
                    .help("destroy_all_inheritances_device")
                }
            }
            
            let children = inheritedDevices
                .filter { $0.inheritsFrom == deviceId }
                .map { $0.deviceId }
            
            ForEach(children, id: \.self) { childId in
                TreeNodeView(
                    deviceId: childId,
                    level: level + 1,
                    inheritedDevices: $inheritedDevices,
                    manager: manager,
                    renamedDevices: renamedDevices
                )
            }
        }
    }
}
