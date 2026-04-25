//
//  MainListBottomBarContextMenuCamouflagedIndicator.swift
//  MenuBarUSB
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct MainListBottomBarContextMenuCamouflagedIndicator: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    @Binding var camouflagedIndicator: Bool
    
    var body: some View {
        Button {
            camouflagedIndicator = false
        } label: {
            Label("disable_indicator", systemImage: "eye.slash")
        }

        Divider()

        Button {
            CSM.Camouflaged.clear()
            manager.refresh()
        } label: {
            Label("make_all_visible_again", systemImage: "eye")
        }
        .disabled(CSM.Camouflaged.devices.isEmpty)
    }
}
