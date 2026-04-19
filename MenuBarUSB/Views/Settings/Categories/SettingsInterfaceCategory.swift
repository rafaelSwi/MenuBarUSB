//
//  SettingsInterfaceCategory.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct SettingsInterfaceCategory: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    
    @Binding var activeRowID: UUID?
    
    @AS(Key.hideTechInfo) private var hideTechInfo = false
    @AS(Key.mouseHoverInfo) private var mouseHoverInfo = false
    @AS(Key.hideSecondaryInfo) private var hideSecondaryInfo = false
    @AS(Key.showScrollBar) private var showScrollBar = false
    @AS(Key.longList) private var longList = false
    @AS(Key.bigNames) private var bigNames = false
    @AS(Key.storeDevices) private var storeDevices = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ToggleRow(
                label: "hide_technical_info",
                description: "hide_technical_info_description",
                binding: $hideTechInfo,
                activeRowID: $activeRowID,
                incompatibilities: nil,
                onToggle: { value in
                    if value == false {
                        mouseHoverInfo = false
                    }
                }
            )
            ToggleRow(
                label: "mouse_hover_info",
                description: "mouse_hover_info_description",
                binding: $mouseHoverInfo,
                activeRowID: $activeRowID,
                incompatibilities: nil,
                disabled: !hideTechInfo,
                onToggle: { _ in }
            )
            ToggleRow(
                label: "hide_secondary_info",
                description: "hide_secondary_info_description",
                binding: $hideSecondaryInfo,
                activeRowID: $activeRowID,
                incompatibilities: nil,
                onToggle: { _ in }
            )
            ToggleRow(
                label: "show_scrollbar",
                description: "show_scrollbar_description",
                binding: $showScrollBar,
                activeRowID: $activeRowID,
                incompatibilities: nil,
                onToggle: { _ in }
            )
            ToggleRow(
                label: "long_list",
                description: "long_list_description",
                binding: $longList,
                activeRowID: $activeRowID,
                incompatibilities: nil,
                onToggle: { _ in }
            )
            ToggleRow(
                label: "big_names",
                description: "big_names_description",
                binding: $bigNames,
                activeRowID: $activeRowID,
                incompatibilities: nil,
                onToggle: { _ in }
            )
            ToggleRow(
                label: "show_previously_connected",
                description: "show_previously_connected_description",
                binding: $storeDevices,
                activeRowID: $activeRowID,
                incompatibilities: nil,
                willRestart: true,
                onToggle: { _ in Utils.App.restart() }
            )
        }
    }
}
