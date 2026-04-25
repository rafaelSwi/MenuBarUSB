//
//  MainListDeviceListContextMenuCharger.swift
//  MenuBarUSB
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct MainListDeviceListContextMenuCharger: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    
    @AS(Key.powerSupplyAsCharger) private var powerSupplyAsCharger = false
    @AS(Key.powerSourceInfo) private var powerSourceInfo = false
    
    var body: some View {
        Button {
            powerSupplyAsCharger.toggle()
        } label: {
            let text = powerSupplyAsCharger ? "revert_to_the_original_name" : "rename_to_charger"
            Label(text.localized, systemImage: "pencil")
        }
        Divider()
        Button {
            powerSourceInfo = false
            manager.refresh()
        } label: {
            Label("hide_charger_information", systemImage: "eye.slash")
        }
    }
}
