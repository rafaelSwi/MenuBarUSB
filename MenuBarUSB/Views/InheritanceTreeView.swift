//
//  InheritanceTreeView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth Swierczynski on 21/09/25.
//

import SwiftUI

struct InheritanceTreeView: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    @Binding var currentWindow: AppWindow
    
    @CodableAppStorage(StorageKeys.renamedDevices) private var renamedDevices: [RenamedDevice] = []
    @CodableAppStorage(StorageKeys.inheritedDevices) private var inheritedDevices: [HeritageDevice] = []
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .center, spacing: 6) {
                    
                    Text("inheritance_tree")
                        .font(.title2)
                        .padding(.bottom, 10)
                    
                    let allIds = Set(inheritedDevices.map { $0.deviceId } + inheritedDevices.map { $0.inheritsFrom })
                    let childIds = Set(inheritedDevices.map { $0.deviceId })
                    let rootIds = Array(allIds.subtracting(childIds))
                    
                    ForEach(rootIds, id: \.self) { rootId in
                        TreeNodeView(
                            deviceId: rootId,
                            level: 0,
                            inheritedDevices: $inheritedDevices,
                            manager: manager,
                            renamedDevices: renamedDevices
                        )
                    }
                }
                .padding(15)
            }
            
            Spacer()
            
            HStack {
                Text("inheritance_tree_warning")
                    .font(.footnote)
                Spacer()
                Button(action: { currentWindow = .settings }) {
                    Label("back", systemImage: "arrow.uturn.backward")
                }
            }
        }
        .padding(10)
        .frame(minWidth: 465, minHeight: 585)
    }
}
