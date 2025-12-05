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
    
    @State private var storedNames: Dictionary<String, String> = [:]

    private var isConnected: Bool {
        let device = manager.devices.first(where: { $0.item.uniqueId == deviceId })
        return device != nil
    }

    private var showXmark: Bool {
        return xmarked || hoveringTrash
    }
    
    private var deviceName: String? {
        let id = deviceId
        let dictName = storedNames[id]
        if id == "power" { return "power_supply".localized }
        if dictName != nil { return dictName }
        let renamedName = CSM.Renamed[id]?.name
        if renamedName != nil { return renamedName }
        let storedName = CSM.Stored[id]?.name
        if storedName != nil { return storedName }
        let name = manager.devices.first(where: { $0.item.uniqueId == id })?.item.name
        if name != nil {
            DispatchQueue.main.async {
                storedNames[id] = name
            }
        }
        return name
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
                    if level > 0 { CSM.Heritage.remove(withId: deviceId) }
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
                    if level > 0 {
                        hoveringTrash = hovering
                    }
                }

                Rectangle()
                    .frame(width: CGFloat(level) * 12, height: 1)
                    .opacity(level > 0 ? 0.5 : 0)

                Text(deviceName ?? "no_info".localized)
                    .font(.system(size: 14, weight: deviceName == nil ? .regular : .semibold))
                    .foregroundColor(deviceName == nil ? .secondary : .primary)
                    .lineLimit(1)

                if showXmark {
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
