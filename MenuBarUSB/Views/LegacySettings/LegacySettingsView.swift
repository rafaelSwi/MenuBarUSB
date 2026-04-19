//
//  LegacySettingsView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import AppKit
import ServiceManagement
import SwiftUI

struct LegacySettingsView: View {
    
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject var manager: USBDeviceManager

    @State private var showMessage: Bool = false

    @State private var activeRowID: UUID? = nil

    @State private var showSystemOptions = false
    @State private var showInterfaceOptions = false
    @State private var showUsbOptions = false
    @State private var showContextMenuOptions = false
    @State private var showHeritageOptions = false
    @State private var showOthersOptions = false
    @State private var showDonateOptions = false
    @State private var showStorageOptions = false

    private func untoggleAll() {
        showSystemOptions = false
        showInterfaceOptions = false
        showUsbOptions = false
        showOthersOptions = false
        showContextMenuOptions = false
        showStorageOptions = false
        showHeritageOptions = false
        showDonateOptions = false
    }

    var body: some View {

        ZStack {
            
            Image(systemName: "gear")
                .font(.system(size: 350))
                .opacity(0.03)
            
            VStack(alignment: .leading, spacing: 20) {
                LegacySettingsHorizontalTopBar(showDonateOptions: $showDonateOptions, untoggleAll: untoggleAll)

                Divider()

                HStack(alignment: .center) {
                    LegacySettingsCategoryButton(label: "system_category", toggle: $showSystemOptions, untoggleAll: untoggleAll)
                    LegacySettingsCategoryButton(label: "ui_category", toggle: $showInterfaceOptions, untoggleAll: untoggleAll)
                    LegacySettingsCategoryButton(label: "usb_category", toggle: $showUsbOptions, untoggleAll: untoggleAll)
                    LegacySettingsCategoryButton(label: "rmb", toggle: $showContextMenuOptions, untoggleAll: untoggleAll)
                    LegacySettingsCategoryButton(label: "heritage_category", toggle: $showHeritageOptions, untoggleAll: untoggleAll)
                    LegacySettingsCategoryButton(label: "others_category", toggle: $showOthersOptions, untoggleAll: untoggleAll)
                    LegacySettingsCategoryButton(label: "storage_category", toggle: $showStorageOptions, untoggleAll: untoggleAll)
                }

                VStack(alignment: .leading, spacing: 6) {
                    
                    if showSystemOptions {
                        LegacySettingsSystemCategory(activeRowID: $activeRowID)
                    }

                    if showInterfaceOptions {
                        LegacySettingsInterfaceCategory(activeRowID: $activeRowID)
                    }

                    if showUsbOptions {
                        LegacySettingsUSBCategory(activeRowID: $activeRowID)
                    }

                    if showContextMenuOptions {
                        LegacySettingsContextMenuCategory(activeRowID: $activeRowID)
                    }

                    if showHeritageOptions {
                        LegacySettingsHeritageCategory(activeRowID: $activeRowID)
                    }

                    if showOthersOptions {
                        LegacySettingsOthersCategory(activeRowID: $activeRowID)
                    }
                    
                    if showStorageOptions {
                        LegacySettingsStorageCategory(showOthersOptions: $showOthersOptions)
                    }

                    if showDonateOptions {
                        LegacySettingsDonateCategory()
                    }
                }
                Spacer()

                LegacySettingsHorizontalBottomBar()
            }
        }
        .padding(10)
        .frame(minWidth: 700, minHeight: 580)
    }
}
