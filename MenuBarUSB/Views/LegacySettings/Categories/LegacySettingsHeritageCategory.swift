//
//  LegacySettingsHeritageCategory.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct LegacySettingsHeritageCategory: View {
    
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject var manager: USBDeviceManager
    
    @Binding var activeRowID: UUID?
    
    @AS(Key.disableInheritanceLayout) private var disableInheritanceLayout = false
    @AS(Key.increasedIndentationGap) private var increasedIndentationGap = false
    
    var body: some View {
        ToggleRow(
            label: "disable_inheritance_layout",
            description: "disable_inheritance_layout_description",
            binding: $disableInheritanceLayout,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { _ in increasedIndentationGap = false }
        )
        ToggleRow(
            label: "increased_indentation_gap",
            description: "increased_indentation_gap_description",
            binding: $increasedIndentationGap,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            disabled: disableInheritanceLayout,
            onToggle: { _ in }
        )
        Spacer()
            .frame(height: 2)
        
        Button("view_inheritance_tree") {
            openWindow(id: "inheritance_tree")
        }
    }
}
