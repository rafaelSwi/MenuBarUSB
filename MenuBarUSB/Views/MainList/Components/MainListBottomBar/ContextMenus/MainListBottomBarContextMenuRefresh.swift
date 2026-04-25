//
//  MainListBottomBarContextMenuRefresh.swift
//  MenuBarUSB
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct MainListBottomBarContextMenuRefresh: View {
    
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        Button {
            openWindow(id: "connection_logs")
        } label: {
            Label("open_separate_window_to_monitor", systemImage: "macwindow.on.rectangle")
        }
    }
}
