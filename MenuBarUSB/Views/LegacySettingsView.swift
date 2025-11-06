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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) var openURL
    
    @State private var showMessage: Bool = false
    
    @State private var activeRowID: UUID? = nil
    
    @State private var tryingToResetSettings = false
    @State private var tryingToDeleteDeviceHistory = false
    @State private var checkingUpdate = false
    @State private var updateAvailable = false
    @State private var latestVersion: String = ""
    @State private var releaseURL: URL? = nil
    
    @State private var hoveringInfo: Bool = false
    
    @State private var showSystemOptions = false
    @State private var showInterfaceOptions = false
    @State private var showInfoOptions = false
    @State private var showContextMenuOptions = false
    @State private var showEthernetOptions = false
    @State private var showOthersOptions = false
    
    @AS(Key.launchAtLogin) private var launchAtLogin = false
    @AS(Key.convertHexa) private var convertHexa = false
    @AS(Key.longList) private var longList = false
    @AS(Key.hideTechInfo) private var hideTechInfo = false
    @AS(Key.showPortMax) private var showPortMax = false
    @AS(Key.contextMenuCopyAll) private var contextMenuCopyAll = false
    @AS(Key.renamedIndicator) private var renamedIndicator = false
    @AS(Key.camouflagedIndicator) private var camouflagedIndicator = false
    @AS(Key.showNotifications) private var showNotifications = false
    @AS(Key.newVersionNotification) private var newVersionNotification = false
    @AS(Key.reduceTransparency) private var reduceTransparency = false
    @AS(Key.disableNotifCooldown) private var disableNotifCooldown = false
    @AS(Key.disableHaptic) private var disableHaptic = false
    @AS(Key.forceEnglish) private var forceEnglish = false
    @AS(Key.showEthernet) private var showEthernet = false
    @AS(Key.internetMonitoring) private var internetMonitoring = false
    @AS(Key.forceDarkMode) private var forceDarkMode = false
    @AS(Key.forceLightMode) private var forceLightMode = false
    @AS(Key.hideSecondaryInfo) private var hideSecondaryInfo = false
    @AS(Key.hideUpdate) private var hideUpdate = false
    @AS(Key.noTextButtons) private var noTextButtons = false
    @AS(Key.storeDevices) private var storeDevices = false
    @AS(Key.storedIndicator) private var storedIndicator = false
    @AS(Key.restartButton) private var restartButton = false
    @AS(Key.mouseHoverInfo) private var mouseHoverInfo = false
    @AS(Key.disableContextMenuSearch) private var disableContextMenuSearch = false
    @AS(Key.searchEngine) private var searchEngine: SearchEngine = .google
    
    func categoryButton(toggle: Binding<Bool>, label: LocalizedStringKey) -> some View {
        return HStack {
            Image(systemName: toggle.wrappedValue ? "chevron.down" : "chevron.up")
            Text(label)
                .font(.system(size: 13.5))
                .fontWeight(.light)
        }
        .onTapGesture {
            manageShowOptions(binding: toggle)
        }
    }
    
    func untoggleShowOptions() {
        showSystemOptions = false
        showInterfaceOptions = false
        showInfoOptions = false
        showOthersOptions = false
        showContextMenuOptions = false
        showEthernetOptions = false
    }
    
    func manageShowOptions(binding: Binding<Bool>) {
        if binding.wrappedValue {
            binding.wrappedValue.toggle()
        } else {
            untoggleShowOptions()
            binding.wrappedValue = true
        }
    }
    
    func toggleLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Error:", error)
        }
    }
    
    private func checkForUpdate() {
        checkingUpdate = true
        updateAvailable = false
        latestVersion = ""
        releaseURL = nil
        
        guard
            let url = URL(
                string: "https://api.github.com/repos/rafaelSwi/MenuBarUSB/releases/latest")
        else {
            checkingUpdate = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            defer { checkingUpdate = false }
            guard let data = data, error == nil else { return }
            
            if let release = try? JSONDecoder().decode(GitHubRelease.self, from: data) {
                let latest = release.tag_name.replacingOccurrences(of: "v", with: "")
                latestVersion = latest
                releaseURL = URL(string: release.html_url)
                
                DispatchQueue.main.async {
                    updateAvailable = Utils.App.isVersion(Utils.App.appVersion, olderThan: latest)
                    Utils.System.playSound(updateAvailable ? "Submarine" : "Glass")
                }
            }
        }.resume()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MenuBarUSB")
                        .font(.title2)
                        .bold()
                    Text(
                        String(
                            format: NSLocalizedString("version", comment: "APP VERSION"),
                            Utils.App.appVersion
                        )
                    )
                    .font(.footnote)
                    .foregroundColor(.secondary)
                }
                Spacer()
                
                if updateAvailable, let releaseURL {
                    HStack(alignment: .center, spacing: 6) {
                        Button(action: {
                            updateAvailable = false
                            latestVersion = ""
                        }) {
                            Image(systemName: "x.circle")
                        }
                        
                        Link(
                            "\(String(localized: "open_download_page")) (v\(latestVersion))",
                            destination: releaseURL
                        )
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                if !updateAvailable {
                    HStack {
                        if !hideUpdate {
                            Button {
                                checkForUpdate()
                            } label: {
                                if checkingUpdate {
                                    ProgressView()
                                } else {
                                    Label(
                                        !latestVersion.isEmpty ? "updated" : "check_for_updates",
                                        systemImage: "checkmark.circle"
                                    )
                                }
                            }
                            .buttonStyle(.bordered)
                            .contextMenu {
                                Button {
                                    checkForUpdate()
                                } label: {
                                    Label("check_for_updates", systemImage: "magnifyingglass")
                                }
                                Button {
                                    if let url = URL(
                                        string: "https://github.com/rafaelSwi/MenuBarUSB")
                                    {
                                        openURL(url)
                                    }
                                } label: {
                                    Label("open_github_page", systemImage: "globe")
                                }
                                Button {
                                    hideUpdate = true
                                } label: {
                                    Label("hide", systemImage: "eye.slash")
                                }
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                categoryButton(toggle: $showSystemOptions, label: "system_category")
                
                if showSystemOptions {
                    ToggleRow(
                        label: String(localized: "open_on_startup"),
                        description: String(localized: "open_on_startup_description"),
                        binding: $launchAtLogin,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: { value in
                            toggleLoginItem(enabled: value)
                        }
                    )
                    ToggleRow(
                        label: String(localized: "new_version_notification"),
                        description: String(localized: "new_version_notification_description"),
                        binding: $newVersionNotification,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: { _ in }
                    )
                    ToggleRow(
                        label: String(localized: "reduce_transparency"),
                        description: String(localized: "reduce_transparency_description"),
                        binding: $reduceTransparency,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        disabled: forceDarkMode || forceLightMode,
                        onToggle: { _ in }
                    )
                    ToggleRow(
                        label: String(localized: "show_notification"),
                        description: String(localized: "show_notification_description"),
                        binding: $showNotifications,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: { value in
                            if value == false {
                                disableNotifCooldown = false
                            } else {
                                Utils.System.requestNotificationPermission()
                            }
                        }
                    )
                    ToggleRow(
                        label: String(localized: "disable_notification_cooldown"),
                        description: String(localized: "disable_notification_cooldown_description"),
                        binding: $disableNotifCooldown,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        disabled: showNotifications == false,
                        onToggle: { _ in }
                    )
                }
                
                categoryButton(toggle: $showInterfaceOptions, label: "ui_category")
                
                if showInterfaceOptions {
                    ToggleRow(
                        label: String(localized: "hide_technical_info"),
                        description: String(localized: "hide_technical_info_description"),
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
                        label: String(localized: "mouse_hover_info"),
                        description: String(localized: "mouse_hover_info_description"),
                        binding: $mouseHoverInfo,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        disabled: !hideTechInfo,
                        onToggle: { _ in }
                    )
                    ToggleRow(
                        label: String(localized: "hide_secondary_info"),
                        description: String(localized: "hide_secondary_info_description"),
                        binding: $hideSecondaryInfo,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: { _ in }
                    )
                    ToggleRow(
                        label: String(localized: "long_list"),
                        description: String(localized: "long_list_description"),
                        binding: $longList,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: { _ in }
                    )
                    ToggleRow(
                        label: String(localized: "show_previously_connected"),
                        description: String(localized: "show_previously_connected_description"),
                        binding: $storeDevices,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: { _ in }
                    )
                    ToggleRow(
                        label: String(localized: "stored_indicator"),
                        description: String(localized: "stored_indicator_description"),
                        binding: $storedIndicator,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: { _ in }
                    )
                    ToggleRow(
                        label: String(localized: "hidden_indicator"),
                        description: String(localized: "hidden_indicator_description"),
                        binding: $camouflagedIndicator,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: { _ in }
                    )
                    ToggleRow(
                        label: String(localized: "renamed_indicator"),
                        description: String(localized: "renamed_indicator_description"),
                        binding: $renamedIndicator,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: { _ in }
                    )
                    
                    HStack {
                        
                        Button("delete_device_history") {
                            tryingToDeleteDeviceHistory = true
                        }
                        .disabled(tryingToDeleteDeviceHistory || CSM.Stored.devices.isEmpty)
                        .help("(\(CSM.Stored.devices.count))")
                        
                        if (tryingToDeleteDeviceHistory) {
                            Button("cancel") {
                                tryingToDeleteDeviceHistory = false
                            }
                            Button("confirm") {
                                CSM.Stored.clear()
                                tryingToDeleteDeviceHistory = false
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                
                categoryButton(toggle: $showInfoOptions, label: "usb_category")
                
                if showInfoOptions {
                    Text("renamed_devices")
                        .font(.title2)
                    
                    Button {
                        CSM.Renamed.clear()
                    } label: {
                        Label("undo_all", systemImage: "trash")
                    }
                    .disabled(CSM.Renamed.devices.isEmpty)
                    
                    Text("hidden_devices")
                        .font(.title2)
                    
                    Button {
                        CSM.Camouflaged.clear()
                    } label: {
                        Label("undo_all", systemImage: "trash")
                    }
                    .disabled(CSM.Camouflaged.devices.isEmpty)
                    .help("make_all_visible_again")
                    
                    ToggleRow(
                        label: String(localized: "show_port_max"),
                        description: String(localized: "show_port_max_description"),
                        binding: $showPortMax,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        disabled: hideTechInfo && !mouseHoverInfo,
                        onToggle: { _ in }
                    )
                    ToggleRow(
                        label: String(localized: "convert_hexa"),
                        description: String(localized: "convert_hexa_description"),
                        binding: $convertHexa,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        disabled: hideTechInfo && !mouseHoverInfo,
                        onToggle: { _ in }
                    )
                }
                
                categoryButton(toggle: $showContextMenuOptions, label: "context_menu_category")
                
                if showContextMenuOptions {
                    ToggleRow(
                        label: String(localized: "disable_context_menu_search"),
                        description: String(localized: "disable_context_menu_search_description"),
                        binding: $disableContextMenuSearch,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: { _ in }
                    )
                    ToggleRow(
                        label: String(localized: "allow_copying_individual"),
                        description: String(localized: "allow_copying_individual_description"),
                        binding: $contextMenuCopyAll,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: { _ in }
                    )
                    HStack {
                        Text("search_engine")
                        Menu(searchEngine.rawValue) {
                            ForEach(SearchEngine.allCases, id: \.self) { engine in
                                Button {
                                    searchEngine = engine
                                } label: {
                                    Text(engine.rawValue)
                                }
                            }
                        }
                        .disabled(disableContextMenuSearch)
                        .frame(maxWidth: 100)
                    }
                }
                
                categoryButton(toggle: $showEthernetOptions, label: "ethernet_category")
                
                if (showEthernetOptions) {
                    ToggleRow(
                        label: String(localized: "ethernet_connected_icon"),
                        description: String(localized: "ethernet_connected_icon_description"),
                        binding: $showEthernet,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: { value in
                            if (value == true) {
                                Utils.App.restart()
                            }
                        }
                    )
                    Text("enabling_this_will_cause_restart")
                        .font(.footnote)
                        .padding(.bottom, 3)
                        .foregroundStyle(.gray)
                }
                
                categoryButton(toggle: $showOthersOptions, label: "others_category")
                
                if showOthersOptions {
                    if Locale.current.language.languageCode?.identifier != "en" {
                        ToggleRow(
                            label: String(localized: "force_english"),
                            description: String(localized: "force_english_description"),
                            binding: $forceEnglish,
                            activeRowID: $activeRowID,
                            incompatibilities: nil,
                            onToggle: { _ in Utils.App.restart() }
                        )
                    }
                    ToggleRow(
                        label: String(localized: "hide_check_update"),
                        description: String(localized: "hide_check_update_description"),
                        binding: $hideUpdate,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: { _ in }
                    )
                    ToggleRow(
                        label: String(localized: "no_text_buttons"),
                        description: String(localized: "no_text_buttons_description"),
                        binding: $noTextButtons,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: { _ in }
                    )
                    ToggleRow(
                        label: String(localized: "restart_button"),
                        description: String(localized: "restart_button_description"),
                        binding: $restartButton,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: { _ in }
                    )
                    ToggleRow(
                        label: String(localized: "disable_haptic_feedback"),
                        description: String(localized: "disable_haptic_feedback_description"),
                        binding: $disableHaptic,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: { _ in }
                    )
                    
                    Button {
                        tryingToResetSettings = true
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill.badge.gearshape")
                            Text("restore_default_settings")
                        }
                    }
                    .disabled(tryingToResetSettings)
                    
                    if tryingToResetSettings {
                        HStack(spacing: 12) {
                            Text("are_you_sure")
                            Button("no") {
                                tryingToResetSettings = false
                            }
                            Button("yes_confirm") {
                                Utils.App.deleteStorageData()
                                tryingToResetSettings = false
                                showOthersOptions = false
                                Utils.System.playSound("Bottle")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                    Utils.App.restart()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            Spacer()
            
            HStack {
                ZStack(alignment: .bottomLeading) {
                    if hoveringInfo {
                        Text("legacy_settings_description")
                            .font(.caption)
                            .offset(y: -40)
                    }
                    
                    Image(systemName: "info.circle")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .onHover { hovering in
                            hoveringInfo = hovering
                        }
                        .padding(4)
                }
                Spacer()
                Button("close") {
                    dismiss()
                }
            }
        }
        .padding(10)
        .frame(minWidth: 465, minHeight: 690)
        .appBackground(reduceTransparency)
    }
}
