//
//  SettingsHorizontalTopBarContextMenuDonate.swift
//  MenuBarUSB
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct SettingsHorizontalTopBarContextMenuDonate: View {
    
    @Binding var currentWindow: AppWindow
    
    @AS(Key.hideDonate) private var hideDonate = false
    
    var body: some View {
        Button {
            currentWindow = .donate
        } label: {
            Label("open", systemImage: "arrow.up.right.square")
        }
        Divider()
        Button {
            hideDonate = true
        } label: {
            Label("hide_button", systemImage: "eye.slash")
        }
    }
}
