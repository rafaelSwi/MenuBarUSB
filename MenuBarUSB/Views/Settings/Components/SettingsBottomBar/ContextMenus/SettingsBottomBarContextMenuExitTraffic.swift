//
//  SettingsBottomBarContextMenuExitTraffic.swift
//  MenuBarUSB
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct SettingsBottomBarContextMenuExitTraffic: View {
    
    @Binding var currentWindow: AppWindow
    
    var body: some View {
        Button {
            currentWindow = .devices
        } label: {
            Label("back_without_resume", systemImage: "arrow.uturn.backward")
        }
    }
}
