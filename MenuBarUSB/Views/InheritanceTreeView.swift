//
//  InheritanceTreeView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth Swierczynski on 21/09/25.
//

import SwiftUI

struct InheritanceTreeView: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    @Environment(\.dismiss) private var dismiss
    
    @Binding var currentWindow: AppWindow

    @State private var refreshID = UUID()
    @State var hoveringInfo: Bool = false

    @AS(Key.storeDevices) private var storeDevices = false
    
    let window: Bool

    private func refresh() {
        manager.refresh()
        refreshID = UUID()
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .center, spacing: 6) {
                    Text("inheritance_tree")
                        .font(.title2)
                        .padding(.bottom, 10)

                    let allIds = Set(
                        CSM.Heritage.devices.map { $0.deviceId }
                            + CSM.Heritage.devices.map { $0.inheritsFrom })
                    let childIds = Set(CSM.Heritage.devices.map { $0.deviceId })
                    let rootIds = Array(allIds.subtracting(childIds))

                    ForEach(rootIds, id: \.self) { rootId in
                        TreeNodeView(
                            deviceId: rootId,
                            level: 0,
                            manager: manager,
                            xmarked: false,
                            onRefresh: { refresh() }
                        )
                    }
                }
                .padding(15)
            }

            Spacer()

            HStack {
                ZStack(alignment: .bottomLeading) {
                    if hoveringInfo {
                        Text("inheritance_tree_warning")
                            .font(.caption)
                            .offset(y: -35)
                    }

                    if !storeDevices {
                        Image(systemName: "info.circle")
                            .onHover { hovering in
                                hoveringInfo = hovering
                            }
                    }
                }
                Spacer()
                Button {
                    refresh()
                } label: {
                    Label("refresh", systemImage: "arrow.clockwise")
                }
                if window {
                    Button("close") { dismiss() }
                } else {
                    Button {
                        currentWindow = .settings
                    } label: {
                        Label("back", systemImage: "arrow.uturn.backward")
                    }
                }
            }
            .animation(.bouncy, value: hoveringInfo)
        }
        .padding(10)
        .frame(minWidth: WindowWidth.value, minHeight: 600)
        .id(refreshID)
    }
}
