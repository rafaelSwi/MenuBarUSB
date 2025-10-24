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
    let manager: USBDeviceManager
    let xmarked: Bool
    let onRefresh: () -> Void
    
    @State var hoveringTrash: Bool = false
    
    private var deviceName: String? {
        let device: USBDeviceWrapper? = manager.devices.first(where: { $0.item.uniqueId == deviceId })
        if (device == nil) {
            let stored: StoredDevice? = CSM.Stored.get(withId: deviceId)
            return stored?.name
        } else {
            return device?.item.name
        }
    }
    
    private var isConnected: Bool {
        let device = manager.devices.first(where: { $0.item.uniqueId == deviceId })
        return device != nil
    }
    
    private var showXmark: Bool {
        return xmarked || hoveringTrash
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                
                Circle()
                    .foregroundStyle(isConnected ? .green : .red)
                    .frame(width: 10, height: 10)
                    .help(isConnected ? "ON" : "OFF")
                    
                Spacer()
                    .frame(width: 6)
                
                Button {
                    if (level > 0) { CSM.Heritage.remove(withId: deviceId) }
                    onRefresh()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(level > 0 ? .red : .gray)
                        .imageScale(.small)
                        .opacity(0.7)
                }
                .buttonStyle(.plain)
                .help("destroy_all_inheritances_device")
                .onHover { hovering in
                    if (level > 0) {
                        hoveringTrash = hovering
                    }
                }
                
                Rectangle()
                    .frame(width: CGFloat(level) * 12, height: 1)
                    .opacity(level > 0 ? 0.5 : 0)
                
                Text(deviceName ?? String(localized: "no_info"))
                    .font(.system(size: 14, weight: deviceName == nil ? .regular : .semibold))
                    .foregroundColor(deviceName == nil ? .secondary : .primary)
                    .lineLimit(1)
                
                if (showXmark) {
                    Image(systemName: "xmark")
                        .foregroundStyle(.red)
                }
                
                Spacer()

            }
            .animation(.easeInOut, value: showXmark)

            let children = CSM.Heritage.devices
                .filter { $0.inheritsFrom == deviceId }
                .map { $0.deviceId }

            ForEach(children, id: \.self) { childId in
                TreeNodeView(
                    deviceId: childId,
                    level: level + 1,
                    manager: manager,
                    xmarked: showXmark,
                    onRefresh: onRefresh
                )
            }
        }
    }
}
