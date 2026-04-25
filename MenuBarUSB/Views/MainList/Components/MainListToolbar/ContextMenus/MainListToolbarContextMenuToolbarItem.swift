//
//  MainListToolbarContextMenuToolbarItem.swift
//  MenuBarUSB
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct MainListToolbarContextMenuToolbarItem: View {
    
    var value: Binding<Bool>
    let help: LocalizedStringKey
    let action: (() -> Void)? = nil
    let disableToolbarValues: () -> Void
    
    @AS(Key.listToolBar) private var listToolBar = false
    
    var body: some View {
        Label(help, systemImage: "questionmark.circle")
        Divider()
        if action == nil {
            Button {
                value.wrappedValue.toggle()
            } label: {
                Label("on_off", systemImage: "power")
            }
        }
        Button {
            disableToolbarValues()
        } label: {
            Label("disable_all", systemImage: "bolt.slash")
        }
        Divider()
        Button {
            listToolBar = false
        } label: {
            Label("hide_toolbar", systemImage: "menubar.arrow.up.rectangle")
        }
    }
}
