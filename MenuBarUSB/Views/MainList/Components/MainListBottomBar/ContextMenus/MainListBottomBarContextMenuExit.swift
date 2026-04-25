//
//  MainListBottomBarContextMenuExit.swift
//  MenuBarUSB
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct MainListBottomBarContextMenuExit: View {
    var body: some View {
        Button {
            Utils.App.restart()
        } label: {
            Label("restart", systemImage: "arrow.2.squarepath")
        }
    }
}
