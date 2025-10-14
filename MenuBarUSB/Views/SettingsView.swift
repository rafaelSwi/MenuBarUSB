//
//  SettingsView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    
    @Environment(\.openURL) var openURL
    @EnvironmentObject var manager: USBDeviceManager
    
    @Binding var currentWindow: AppWindow
    
    @State private var showMessage: Bool = false
    @State private var showRenameDevices: Bool = false
    @State private var showCamouflagedDevices: Bool = false
    
    @State private var selectedDeviceToCamouflage: USBDeviceWrapper?
    @State private var selectedDeviceToRename: USBDeviceWrapper?
    @State private var inputText: String = ""
    @State private var textFieldFocused: Bool = false
    @State private var activeRowID: UUID? = nil
    
    @State private var tryingToResetSettings = false
    @State private var tryingToDeleteDeviceHistory = false
    @State private var checkingUpdate = false
    @State private var updateAvailable = false
    @State private var latestVersion: String = ""
    @State private var releaseURL: URL? = nil
    
    @AppStorage(Key.settingsCategory) private var settingsCategory: SettingsCategory = .system
    
    @AppStorage(Key.launchAtLogin) private var launchAtLogin = false
    @AppStorage(Key.convertHexa) private var convertHexa = false
    @AppStorage(Key.longList) private var longList = false
    @AppStorage(Key.hideTechInfo) private var hideTechInfo = false
    @AppStorage(Key.showPortMax) private var showPortMax = false
    @AppStorage(Key.renamedIndicator) private var renamedIndicator = false
    @AppStorage(Key.camouflagedIndicator) private var camouflagedIndicator = false
    @AppStorage(Key.showNotifications) private var showNotifications = false
    @AppStorage(Key.reduceTransparency) private var reduceTransparency = false
    @AppStorage(Key.disableNotifCooldown) private var disableNotifCooldown = false
    @AppStorage(Key.disableInheritanceLayout) private var disableInheritanceLayout = false
    @AppStorage(Key.forceDarkMode) private var forceDarkMode = false
    @AppStorage(Key.forceLightMode) private var forceLightMode = false
    @AppStorage(Key.increasedIndentationGap) private var increasedIndentationGap = false
    @AppStorage(Key.hideSecondaryInfo) private var hideSecondaryInfo = false
    @AppStorage(Key.hideUpdate) private var hideUpdate = false
    @AppStorage(Key.hideDonate) private var hideDonate = false
    @AppStorage(Key.noTextButtons) private var noTextButtons = false
    @AppStorage(Key.hideCount) private var hideCount = false
    @AppStorage(Key.numberRepresentation) private var numberRepresentation: NumberRepresentation = .base10
    @AppStorage(Key.macBarIcon) private var macBarIcon: String = "cable.connector"
    @AppStorage(Key.hideMenubarIcon) private var hideMenubarIcon = false
    @AppStorage(Key.restartButton) private var restartButton = false
    @AppStorage(Key.mouseHoverInfo) private var mouseHoverInfo = false
    @AppStorage(Key.profilerButton) private var profilerButton = false
    @AppStorage(Key.disableContextMenuSearch) private var disableContextMenuSearch = false
    @AppStorage(Key.showEthernet) private var showEthernet = false
    @AppStorage(Key.internetMonitoring) private var internetMonitoring = false
    @AppStorage(Key.disableHaptic) private var disableHaptic = false
    @AppStorage(Key.trafficButton) private var trafficButton = false
    @AppStorage(Key.disableTrafficButtonLabel) private var disableTrafficButtonLabel = false
    @AppStorage(Key.newVersionNotification) private var newVersionNotification = false
    @AppStorage(Key.contextMenuCopyAll) private var contextMenuCopyAll = false
    @AppStorage(Key.fastMonitor) private var fastMonitor = false
    @AppStorage(Key.storeDevices) private var storeDevices = false
    @AppStorage(Key.storedIndicator) private var storedIndicator = false
    @AppStorage(Key.forceEnglish) private var forceEnglish = false
    @AppStorage(Key.searchEngine) private var searchEngine: SearchEngine = .google
    
    @CodableAppStorage(Key.inheritedDevices) private var inheritedDevices:
    [HeritageDevice] = []

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

    private var isTrafficMonitoringPausedForSettings: Bool {
        return internetMonitoring && !manager.trafficMonitorRunning && manager.ethernetCableConnected
    }

    var body: some View {
        let anyBottomOptionInUse: Bool = showRenameDevices || showCamouflagedDevices

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
                                Divider()
                                Button {
                                    hideUpdate = true
                                } label: {
                                    Label("hide_button", systemImage: "eye.slash")
                                }
                            }
                        }

                        if !hideDonate {
                            Button {
                                currentWindow = .donate
                            } label: {
                                Label("donate", systemImage: "hand.thumbsup.circle")
                            }
                            .disabled(anyBottomOptionInUse)
                            .contextMenu {
                                Button {
                                    currentWindow = .donate
                                } label: {
                                    Label("open", systemImage: "arrow.up.right.square")
                                }
                                Divider()
                                Button {
                                    hideDonate = true
                                } label: {
                                    Label("hide_button", systemImage: "eye.slash")
                                }
                            }
                        }
                    }
                }
            }

            if isTrafficMonitoringPausedForSettings {
                HStack {
                    Image(systemName: "network.slash")
                    Text("traffic_monitor_inactive_settings")
                        .font(.footnote)
                }
                .foregroundStyle(.white)
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .background(Color.black.opacity(0.7))
                .cornerRadius(5)
                .onAppear {
                    manager.stopEthernetMonitoring()
                }
                .contextMenu {
                    Button {
                       manager.startEthernetMonitoring()
                        currentWindow = .devices
                    } label: {
                        Label("exit_settings_and_resume", systemImage: "arrow.uturn.backward")
                    }
                }
            } else {
                Divider()
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Spacer()
                    CategoryButton(category: .system, label: "systemCategory", image: "settings_general", settingsCategory: $settingsCategory, disabled: anyBottomOptionInUse)
                    CategoryButton(category: .icon, label: "icon_category", image: "settings_icon", settingsCategory: $settingsCategory, disabled: anyBottomOptionInUse)
                    CategoryButton(category: .interface, label: "uiCategory", image: "settings_interface", settingsCategory: $settingsCategory, disabled: anyBottomOptionInUse)
                    CategoryButton(category: .usb, label: "usbCategory", image: "settings_info", settingsCategory: $settingsCategory, disabled: anyBottomOptionInUse)
                    CategoryButton(category: .contextMenu, label: "context_menu_category", image: "settings_contextmenu", settingsCategory: $settingsCategory, disabled: anyBottomOptionInUse)
                    CategoryButton(category: .ethernet, label: "ethernetCategory", image: "settings_ethernet", settingsCategory: $settingsCategory, disabled: anyBottomOptionInUse)
                    CategoryButton(category: .heritage, label: "heritageCategory", image: "settings_heritage", settingsCategory: $settingsCategory, disabled: anyBottomOptionInUse)
                    CategoryButton(category: .others, label: "othersCategory", image: "settings_others", settingsCategory: $settingsCategory, disabled: anyBottomOptionInUse)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5)

                Text(LocalizedStringKey(settingsCategory.rawValue))
                    .font(.title)
                    .padding(.vertical, 10)

                if settingsCategory == .system {
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
                        label: String(localized: "reduce_transparency"),
                        description: String(localized: "reduce_transparency_description"),
                        binding: $reduceTransparency,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        disabled: forceDarkMode || forceLightMode,
                        onToggle: { _ in }
                    )
                    ToggleRow(
                        label: String(localized: "force_dark_mode"),
                        description: String(localized: "force_dark_mode_description"),
                        binding: $forceDarkMode,
                        activeRowID: $activeRowID,
                        incompatibilities: [forceLightMode],
                        onToggle: { value in
                            if value == true {
                                forceLightMode = false
                            }
                        }
                    )
                    ToggleRow(
                        label: String(localized: "force_light_mode"),
                        description: String(localized: "force_light_mode_description"),
                        binding: $forceLightMode,
                        activeRowID: $activeRowID,
                        incompatibilities: [forceDarkMode],
                        onToggle: { value in
                            if value == true {
                                forceDarkMode = false
                            }
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
                        label: String(localized: "show_notification"),
                        description: String(localized: "show_notification_description"),
                        binding: $showNotifications,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: { value in
                            if value {
                                Utils.System.requestNotificationPermission()
                            } else {
                                disableNotifCooldown = false
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

                if settingsCategory == .icon {
                    VStack(alignment: .leading, spacing: 16) {
                        ToggleRow(
                            label: String(localized: "hide_menubar_icon"),
                            description: String(localized: "hide_menubar_icon_description"),
                            binding: $hideMenubarIcon,
                            activeRowID: $activeRowID,
                            incompatibilities: nil,
                            disabled: hideCount,
                            onToggle: { _ in hideCount = false }
                        )
                        ToggleRow(
                            label: String(localized: "hide_count"),
                            description: String(localized: "hide_count_description"),
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
                                Text(NumberConverter(manager.devices.count).convert())
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
                                                    NumberConverter(manager.devices.count).convert()
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

                if settingsCategory == .interface {
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
                    
                        Button("delete_device_history") {
                            tryingToDeleteDeviceHistory = true
                        }
                        .disabled(tryingToDeleteDeviceHistory || CodableStorageManager.Stored.devices.isEmpty)
                        .help("(\(CodableStorageManager.Stored.devices.count))")
                        .padding(.vertical, 5)
                    
                    if (tryingToDeleteDeviceHistory) {
                        HStack(spacing: 6) {
                            Text("are_you_sure")
                            Button("no") {
                                tryingToDeleteDeviceHistory = false
                            }
                            Button("yes_confirm") {
                                CodableStorageManager.Stored.clear()
                                tryingToDeleteDeviceHistory = false
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }

                if settingsCategory == .usb {
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
                    Button {
                        showRenameDevices.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "pencil.and.scribble")
                            Text("rename_device")
                        }
                    }
                    .disabled(anyBottomOptionInUse)
                    .padding(.vertical, 5)
                    .contextMenu {
                        Button {
                            CodableStorageManager.Renamed.clear()
                            manager.refresh()
                        } label: {
                            Label("undo_all", systemImage: "trash")
                        }
                        .disabled(CodableStorageManager.Renamed.devices.isEmpty)
                    }

                    Button {
                        showCamouflagedDevices.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "eye.slash")
                            Text("hide_device")
                        }
                    }
                    .disabled(anyBottomOptionInUse)
                    .contextMenu {
                        Button {
                            CodableStorageManager.Camouflaged.clear()
                            manager.refresh()
                        } label: {
                            Label("undo_all", systemImage: "trash")
                        }
                        .disabled(CodableStorageManager.Camouflaged.devices.isEmpty)
                    }
                }

                if settingsCategory == .contextMenu {
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
                        .frame(width: 130)
                        .disabled(disableContextMenuSearch)
                        .padding(.vertical, 5)
                    }
                }

                if settingsCategory == .ethernet {
                    ToggleRow(
                        label: String(localized: "ethernet_connected_icon"),
                        description: String(localized: "ethernet_connected_icon_description"),
                        binding: $showEthernet,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        disabled: hideMenubarIcon,
                        onToggle: { value in
                            manager.refresh()
                            if value == false {
                                manager.stopEthernetMonitoring()
                                internetMonitoring = false
                                trafficButton = false
                            }
                        }
                    )
                    ToggleRow(
                        label: String(localized: "internet_monitoring_icon"),
                        description: String(localized: "internet_monitoring_icon_description"),
                        binding: $internetMonitoring,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        disabled: hideMenubarIcon || !showEthernet,
                        onToggle: { value in
                            if value == true {
                                if manager.ethernetCableConnected {
                                    manager.startEthernetMonitoring()
                                    currentWindow = .devices
                                }
                            } else {
                                manager.stopEthernetMonitoring()
                                trafficButton = false
                            }
                        }
                    )
                    ToggleRow(
                        label: String(localized: "stop_traffic_monitor_button"),
                        description: String(localized: "stop_traffic_monitor_button_description"),
                        binding: $trafficButton,
                        activeRowID: $activeRowID,
                        incompatibilities: [profilerButton, restartButton],
                        disabled: !showEthernet || !internetMonitoring,
                        onToggle: { value in
                            if value == true {
                                profilerButton = false
                                restartButton = false
                            }
                        }
                    )
                    ToggleRow(
                        label: String(localized: "stop_traffic_monitor_button_disable_status"),
                        description: String(localized: "stop_traffic_monitor_button_disable_status_description"),
                        binding: $disableTrafficButtonLabel,
                        activeRowID: $activeRowID,
                        incompatibilities: [profilerButton, restartButton],
                        disabled: !showEthernet || !internetMonitoring,
                        onToggle: { _ in }
                    )
                    ToggleRow(
                        label: String(localized: "fast_traffic_monitor"),
                        description: String(localized: "fast_traffic_monitor_description"),
                        binding: $fastMonitor,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        disabled: !internetMonitoring,
                        onToggle: { _ in }
                    )
                }

                if settingsCategory == .heritage {
                    ToggleRow(
                        label: String(localized: "disable_inheritance_layout"),
                        description: String(localized: "disable_inheritance_layout_description"),
                        binding: $disableInheritanceLayout,
                        activeRowID: $activeRowID,
                        incompatibilities: [increasedIndentationGap],
                        onToggle: { _ in increasedIndentationGap = false }
                    )
                    ToggleRow(
                        label: String(localized: "increased_indentation_gap"),
                        description: String(localized: "increased_indentation_gap_description"),
                        binding: $increasedIndentationGap,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        disabled: disableInheritanceLayout,
                        onToggle: { _ in }
                    )
                    Button {
                        currentWindow = .heritage
                    } label: {
                        Label("create_inheritance", systemImage: "plus")
                    }
                    .disabled(anyBottomOptionInUse)
                    .padding(.vertical, 5)

                    Button {
                        currentWindow = .inheritanceTree
                    } label: {
                        Label("view_inheritance_tree", systemImage: "arrow.trianglehead.branch")
                    }
                    .disabled(anyBottomOptionInUse)
                }

                if settingsCategory == .others {
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
                        label: String(localized: "hide_donate"),
                        description: String(localized: "hide_donate_description"),
                        binding: $hideDonate,
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
                        incompatibilities: [profilerButton, trafficButton],
                        onToggle: { value in
                            if value == true {
                                profilerButton = false
                                trafficButton = false
                            }
                        }
                    )
                    ToggleRow(
                        label: String(localized: "profiler_shortcut"),
                        description: String(localized: "profiler_shortcut_description"),
                        binding: $profilerButton,
                        activeRowID: $activeRowID,
                        incompatibilities: [restartButton, trafficButton],
                        onToggle: { value in
                            if value == true {
                                restartButton = false
                                trafficButton = false
                            }
                        }
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
                    .padding(.vertical, 5)

                    if tryingToResetSettings {
                        HStack(spacing: 6) {
                            Text("are_you_sure")
                            Button("no") {
                                tryingToResetSettings = false
                            }
                            Button("yes_confirm") {
                                Utils.App.deleteStorageData()
                                tryingToResetSettings = false
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

            VStack(alignment: .leading) {
                if anyBottomOptionInUse {
                    Button("cancel") {
                        showRenameDevices = false
                        showCamouflagedDevices = false
                        selectedDeviceToRename = nil
                        selectedDeviceToCamouflage = nil
                        inputText = ""
                    }
                }

                HStack {
                    Spacer()

                    if !anyBottomOptionInUse {
                        Button(action: {
                            if isTrafficMonitoringPausedForSettings {
                                manager.startEthernetMonitoring()
                            }
                            currentWindow = .devices
                        }) {
                            if isTrafficMonitoringPausedForSettings {
                                Label("back_and_resume", systemImage: "arrow.uturn.backward")
                                    .contextMenu {
                                        Button {
                                            currentWindow = .devices
                                        } label: {
                                            Label("back_without_resume", systemImage: "arrow.uturn.backward")
                                        }
                                    }
                            } else {
                                Label("back", systemImage: "arrow.uturn.backward")
                            }
                        }
                    }
                }

                if anyBottomOptionInUse {
                    Divider()
                }

                if showCamouflagedDevices {
                    HStack(spacing: 12) {
                        Menu {
                            ForEach(manager.devices, id: \.self) { device in
                                let renamedDevice = CodableStorageManager.Renamed.devices.first {
                                    $0.deviceId == device.item.uniqueId
                                }
                                let buttonLabel = renamedDevice?.name ?? device.item.name
                                Button(buttonLabel) {
                                    selectedDeviceToCamouflage = device
                                }
                            }
                        } label: {
                            Text(
                                selectedDeviceToCamouflage?.item.name ?? String(localized: "device")
                            )
                        }

                        if selectedDeviceToCamouflage != nil {
                            if (inheritedDevices.contains {
                                $0.inheritsFrom == selectedDeviceToCamouflage!.item.uniqueId
                            }) {
                                Text("cant_hide_heir")
                                    .font(.subheadline)
                            } else {
                                Button("confirm") {
                                    CodableStorageManager.Camouflaged.add(withId: selectedDeviceToCamouflage?.item.uniqueId)
                                    selectedDeviceToCamouflage = nil
                                    showCamouflagedDevices = false
                                    manager.refresh()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }

                        if selectedDeviceToCamouflage == nil && !CodableStorageManager.Camouflaged.devices.isEmpty {
                            Button("undo_all") {
                                CodableStorageManager.Camouflaged.clear()
                                showCamouflagedDevices = false
                                manager.refresh()
                            }
                        }

                        Spacer()
                    }
                }

                if showRenameDevices {
                    HStack(spacing: 12) {
                        Menu {
                            ForEach(manager.devices, id: \.self) { device in
                                let renamedDevice = CodableStorageManager.Renamed.devices.first {
                                    $0.deviceId == device.item.uniqueId
                                }
                                let buttonLabel = renamedDevice?.name ?? device.item.name
                                Button(buttonLabel) {
                                    inputText = ""
                                    selectedDeviceToRename = device
                                }
                            }
                        } label: {
                            Text(selectedDeviceToRename?.item.name ?? String(localized: "device"))
                        }

                        if selectedDeviceToRename != nil {
                            CustomTextField(
                                text: $inputText,
                                placeholder: String(localized: "insert_new_name"),
                                maxLength: 30,
                                isFocused: $textFieldFocused
                            )
                            .frame(width: 190)
                            .help("renaming_help")

                            Button(String(localized: "confirm")) {
                                let uniqueId = selectedDeviceToRename!.item.uniqueId
                                if inputText.isEmpty {
                                    CodableStorageManager.Renamed.remove(withId: uniqueId)
                                } else {
                                    CodableStorageManager.Renamed.add(selectedDeviceToRename, inputText)
                                }
                                inputText = ""
                                selectedDeviceToRename = nil
                                showRenameDevices = false
                                manager.refresh()
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        if selectedDeviceToRename == nil && !CodableStorageManager.Renamed.devices.isEmpty {
                            Button(String(localized: "undo_all")) {
                                CodableStorageManager.Renamed.clear()
                                showRenameDevices = false
                                manager.refresh()
                            }
                        }

                        Spacer()
                    }
                }
            }
        }
        .padding(10)
        .frame(minWidth: 465, minHeight: 600)
        .appBackground(reduceTransparency)
    }
}
