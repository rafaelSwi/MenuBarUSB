//
//  MainListToolbar.swift
//  MenuBarUSB
//
//  Created by rafael on 19/04/26.
//

import SwiftUI

struct MainListToolbar: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    
    @AS(Key.toolbarClockOff) private var toolbarClockOff = false
    @AS(Key.showNotifications) private var showNotifications = false
    @AS(Key.indexIndicator) private var indexIndicator = false
    @AS(Key.hideTechInfo) private var hideTechInfo = false
    @AS(Key.mouseHoverInfo) private var mouseHoverInfo = false
    @AS(Key.longList) private var longList = false
    @AS(Key.hideSecondaryInfo) private var hideSecondaryInfo = false
    @AS(Key.bigNames) private var bigNames = false
    @AS(Key.storeDevices) private var storeDevices = false
    @AS(Key.storedIndicator) private var storedIndicator = false
    @AS(Key.camouflagedIndicator) private var camouflagedIndicator = false
    @AS(Key.renamedIndicator) private var renamedIndicator = false
    @AS(Key.noTextButtons) private var noTextButtons = false
    @AS(Key.macBarIcon) private var macBarIcon: String = "cable.connector"
    
    private func toolbarListItemView(
        _ value: Binding<Bool>,
        _ icon: String,
        _ help: LocalizedStringKey,
        _ action: (() -> Void)? = nil
    ) -> some View {
        let color = AssetColors.toolbarButton
        return Button {
            value.wrappedValue.toggle()
            if action != nil {
                action?()
            }
        } label: {
            Image(systemName: icon)
                .toolbarItem()
                .background(value.wrappedValue ? color.opacity(0.24) : .gray.opacity(0.18))
        }
        .buttonStyle(.borderless)
        .foregroundStyle(value.wrappedValue ? color : .gray)
        .help(help)
        .contextMenu {
            MainListToolbarContextMenuToolbarItem(value: value, help: help, disableToolbarValues: disableToolbarValues)
        }
    }
    
    private func disableToolbarValues() {
        showNotifications = false
        indexIndicator = false
        hideTechInfo = false
        mouseHoverInfo = false
        longList = false
        hideSecondaryInfo = false
        bigNames = false
        storeDevices = false
        storedIndicator = false
        camouflagedIndicator = false
        renamedIndicator = false
        noTextButtons = false
    }
    
    var body: some View {
        HStack {
            toolbarListItemView($showNotifications, "bell.fill", "show_notification") {
                if showNotifications {
                    Utils.System.requestNotificationPermission()
                }
            }
            
            toolbarListItemView($indexIndicator, "list.number", "index_indicator")
            
            toolbarListItemView($hideTechInfo, "arrow.down.and.line.horizontal.and.arrow.up", "hide_technical_info")
            
            if hideTechInfo {
                toolbarListItemView($mouseHoverInfo, "rectangle.and.text.magnifyingglass", "mouse_hover_info")
            }
            
            toolbarListItemView($bigNames, "textformat.size", "big_names")
            
            toolbarListItemView($longList, "arrow.up.and.down.text.horizontal", "long_list")
            toolbarListItemView($hideSecondaryInfo, "decrease.indent", "hide_secondary_info")
            toolbarListItemView($storeDevices, "arrow.counterclockwise", "show_previously_connected")
            toolbarListItemView($camouflagedIndicator, "eye.fill", "hidden_indicator")
            toolbarListItemView($noTextButtons, "ellipsis.circle", "no_text_buttons")
            
            Button(action: Utils.System.openSysInfo, label: {
                if noTextButtons {
                    Image(systemName: "info.circle")
                        .toolbarItem()
                } else {
                    Text("info_abbreviation")
                        .fontWeight(.bold)
                        .font(.system(size: 8))
                }
            })
            .buttonStyle(.borderless)
            .opacity(0.6)
            
            Spacer()
            
            Group {
                if toolbarClockOff {
                    Group {
                        Image(systemName: macBarIcon)
                        Text(NumberConverter(manager.count).converted)
                            .padding(.horizontal, 5)
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(.gray)
                } else {
                    BlinkingClock()
                }
            }
            .contextMenu {
                MainListToolbarContextMenuToolbarClock()
            }
        }
        .padding(.horizontal, 3)
        .padding(.top, 1)
    }
}
