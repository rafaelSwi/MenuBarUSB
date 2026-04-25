//
//  SettingsHeritageCategory.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct SettingsHeritageCategory: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    @Environment(\.openWindow) private var openWindow
    
    @Binding var currentWindow: AppWindow
    @Binding var activeRowID: UUID?
    
    @AS(Key.disableInheritanceLayout) private var disableInheritanceLayout = false
    @AS(Key.increasedIndentationGap) private var increasedIndentationGap = false
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ToggleRow(
                label: "disable_inheritance_layout",
                description: "disable_inheritance_layout_description",
                binding: $disableInheritanceLayout,
                activeRowID: $activeRowID,
                incompatibilities: [increasedIndentationGap],
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
                .frame(height: 4)
            
            Button("create_inheritance") {
                currentWindow = .heritage
            }
            
            Spacer()
                .frame(height: 4)
            
            HStack {
                Button("view_inheritance_tree") {
                    currentWindow = .inheritanceTree
                }
                
                Button {
                    openWindow(id: "inheritance_tree")
                } label: {
                    Image(systemName: "macwindow.badge.plus")
                }
                .help("open_in_separate_window")
                .buttonStyle(.plain)
                
            }
        }
    }
}
