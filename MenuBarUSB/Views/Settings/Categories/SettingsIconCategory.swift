//
//  SettingsIconCategory.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct SettingsIconCategory: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    
    @Binding var activeRowID: UUID?
    
    @AS(Key.hideMenubarIcon) private var hideMenubarIcon = false
    @AS(Key.hideCount) private var hideCount = false
    @AS(Key.macBarIcon) private var macBarIcon: String = "cable.connector"
    @AS(Key.numberRepresentation) private var numberRepresentation: NumberRepresentation = .base10
    
    private let icons: [String] = [
        "cable.connector",
        "app.connected.to.app.below.fill",
        "rectangle.connected.to.line.below",
        "mediastick",
        "sdcard",
        "sdcard.fill",
        "bolt.ring.closed",
        "bolt",
        "bolt.fill",
        "wrench.and.screwdriver",
        "wrench.and.screwdriver.fill",
        "externaldrive.connected.to.line.below",
        "externaldrive.connected.to.line.below.fill",
        "powerplug.portrait",
        "powerplug.portrait.fill",
        "powercord",
        "powercord.fill",
        "cat.fill",
        "dog.fill",
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
            
            HStack(spacing: 12) {
                if !hideMenubarIcon {
                    Text("icon")
                    Image(systemName: macBarIcon)
                }
                if !hideCount {
                    Text("numerical_representation")
                    Text(NumberConverter(manager.count).converted)
                        .fontWeight(.bold)
                }
                Spacer()
            }
            
            HStack {
                Menu {
                    ForEach(icons, id: \.self) { item in
                        Button {
                            macBarIcon = item
                        } label: {
                            HStack {
                                Image(systemName: item)
                                if !hideCount {
                                    Text(
                                        NumberConverter(manager.count).converted
                                    )
                                }
                            }
                        }
                    }
                } label: {
                    Label("icon", systemImage: macBarIcon)
                        .background(
                            RoundedRectangle(cornerRadius: 6).stroke(
                                Color.gray.opacity(0.3)))
                }
                .disabled(hideMenubarIcon)
                
                Menu(LocalizedStringKey(numberRepresentation.rawValue)) {
                    let nr: [NumberRepresentation] = [
                        .base10, .egyptian, .greek, .roman,
                    ]
                    ForEach(nr, id: \.self) { item in
                        Button {
                            numberRepresentation = item
                            Utils.App.restart()
                        } label: {
                            Text(LocalizedStringKey(item.rawValue))
                        }
                    }
                }
                .disabled(hideCount)
                .help("numerical_representation")
            }
            
            Text("changes_restart_warning")
                .font(.footnote)
                .foregroundColor(.primary)
                .opacity(0.7)
                .padding(.bottom, 3)
        }
    }
}
