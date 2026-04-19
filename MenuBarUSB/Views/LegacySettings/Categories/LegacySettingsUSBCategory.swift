//
//  LegacySettingsUSBCategory.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct LegacySettingsUSBCategory: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    @Environment(\.openWindow) private var openWindow
    
    @Binding var activeRowID: UUID?
    
    @AS(Key.showPortMax) private var showPortMax = false
    @AS(Key.hideTechInfo) private var hideTechInfo = false
    @AS(Key.mouseHoverInfo) private var mouseHoverInfo = false
    @AS(Key.indexIndicator) private var indexIndicator = false
    @AS(Key.camouflagedIndicator) private var camouflagedIndicator = false
    @AS(Key.storedIndicator) private var storedIndicator = false
    @AS(Key.renamedIndicator) private var renamedIndicator = false
    @AS(Key.hidePinIndicator) private var hidePinIndicator = false
    @AS(Key.storeConnectionLogs) private var storeConnectionLogs = false
    
    var body: some View {
        ToggleRow(
            label: "show_port_max",
            description: "show_port_max_description",
            binding: $showPortMax,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            disabled: hideTechInfo && !mouseHoverInfo,
            onToggle: { _ in }
        )
        ToggleRow(
            label: "index_indicator",
            description: "index_indicator_description",
            binding: $indexIndicator,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { _ in }
        )
        ToggleRow(
            label: "stored_indicator",
            description: "stored_indicator_description",
            binding: $storedIndicator,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { _ in }
        )
        ToggleRow(
            label: "hidden_indicator",
            description: "hidden_indicator_description",
            binding: $camouflagedIndicator,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { _ in }
        )
        ToggleRow(
            label: "renamed_indicator",
            description: "renamed_indicator_description",
            binding: $renamedIndicator,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { _ in }
        )
        ToggleRow(
            label: "hide_pin_indicator",
            description: "hide_pin_indicator_description",
            binding: $hidePinIndicator,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { _ in }
        )
        ToggleRow(
            label: "save_connection_logs",
            description: "save_connection_logs_description",
            binding: $storeConnectionLogs,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { _ in }
        )
        
        Button("view_connection_logs") {
            openWindow(id: "connection_logs")
        }
    }
}
