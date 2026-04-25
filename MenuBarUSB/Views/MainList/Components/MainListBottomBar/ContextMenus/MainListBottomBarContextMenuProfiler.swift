//
//  MainListBottomBarContextMenuProfiler.swift
//  MenuBarUSB
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct MainListBottomBarContextMenuProfiler: View {
    
    @AS(Key.profilerButton) private var profilerButton = false
    
    var body: some View {
        Button {
            profilerButton = false
        } label: {
            Label("hide_button", systemImage: "eye.slash")
        }
    }
}
