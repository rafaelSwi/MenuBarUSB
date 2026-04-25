//
//  MainListToolbarContextMenuToolbarClock.swift
//  MenuBarUSB
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct MainListToolbarContextMenuToolbarClock: View {
    
    @AS(Key.toolbarClockOff) private var toolbarClockOff = false
    
    var body: some View {
        Button(toolbarClockOff ? "switch_to_clock" : "switch_to_device_count") {
            toolbarClockOff.toggle()
        }
    }
}
