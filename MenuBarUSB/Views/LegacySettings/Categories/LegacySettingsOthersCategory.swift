//
//  LegacySettingsOthersCategory.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct LegacySettingsOthersCategory: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    
    @Binding var activeRowID: UUID?
    
    @AS(Key.listToolBar) private var listToolBar = false
    @AS(Key.noTextButtons) private var noTextButtons = false
    @AS(Key.hideUpdate) private var hideUpdate = false
    @AS(Key.hideDonate) private var hideDonate = false
    @AS(Key.disableHaptic) private var disableHaptic = false
    @AS(Key.hideMenubarIcon) private var hideMenubarIcon = false
    @AS(Key.hideCount) private var hideCount = false
    
    var body: some View {
        ToggleRow(
            label: "show_toolbar",
            description: "show_toolbar_description",
            binding: $listToolBar,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { _ in }
        )
        ToggleRow(
            label: "no_text_buttons",
            description: "no_text_buttons_description",
            binding: $noTextButtons,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { _ in }
        )
        ToggleRow(
            label: "hide_check_update",
            description: "hide_check_update_description",
            binding: $hideUpdate,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { _ in }
        )
        ToggleRow(
            label: "hide_donate",
            description: "hide_donate_description",
            binding: $hideDonate,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { _ in }
        )
        ToggleRow(
            label: "disable_haptic_feedback",
            description: "disable_haptic_feedback_description",
            binding: $disableHaptic,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { _ in }
        )
        ToggleRow(
            label: "hide_menubar_icon",
            description: "hide_menubar_icon_description",
            binding: $hideMenubarIcon,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            disabled: hideCount,
            onToggle: { _ in hideCount = false }
        )
        ToggleRow(
            label: "hide_count",
            description: "hide_count_description",
            binding: $hideCount,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            disabled: hideMenubarIcon,
            onToggle: { _ in hideMenubarIcon = false }
        )
        
    }
}
