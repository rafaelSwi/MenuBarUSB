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
    @State private var showHeritageOptions = false
    @State private var showOthersOptions = false

    @AS(Key.launchAtLogin) private var launchAtLogin = false
    @AS(Key.convertHexa) private var convertHexa = false
    @AS(Key.longList) private var longList = false
    @AS(Key.hideTechInfo) private var hideTechInfo = false
    @AS(Key.showPortMax) private var showPortMax = false
    @AS(Key.contextMenuCopyAll) private var contextMenuCopyAll = false
    @AS(Key.renamedIndicator) private var renamedIndicator = false
    @AS(Key.camouflagedIndicator) private var camouflagedIndicator = false
    @AS(Key.listToolBar) private var listToolBar = false
    @AS(Key.showNotifications) private var showNotifications = false
    @AS(Key.newVersionNotification) private var newVersionNotification = false
    @AS(Key.reduceTransparency) private var reduceTransparency = false
    @AS(Key.disableNotifCooldown) private var disableNotifCooldown = false
    @AS(Key.hardwareSound) private var hardwareSound: String = ""
    @AS(Key.playHardwareSound) private var playHardwareSound: Bool = false
    @AS(Key.disableHaptic) private var disableHaptic = false
    @AS(Key.forceEnglish) private var forceEnglish = false
    @AS(Key.showEthernet) private var showEthernet = false
    @AS(Key.showScrollBar) private var showScrollBar = false
    @AS(Key.indexIndicator) private var indexIndicator = false
    @AS(Key.disableInheritanceLayout) private var disableInheritanceLayout = false
    @AS(Key.increasedIndentationGap) private var increasedIndentationGap = false
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
    @AS(Key.disableContextMenuHeritage) private var disableContextMenuHeritage = false
    @AS(Key.windowWidth) private var windowWidth: WindowWidth = .normal
    @AS(Key.searchEngine) private var searchEngine: SearchEngine = .google

    func categoryButton(toggle: Binding<Bool>, label: LocalizedStringKey) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14.5))
                .fontWeight(.light)
                .foregroundColor(.primary)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .lineLimit(1)
        }
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(toggle.wrappedValue ? Color.accentColor.opacity(0.2) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            manageShowOptions(binding: toggle)
        }
    }

    private func setWindowWidth(increase: Bool) {
        let order: [WindowWidth] = [.tiny, .normal, .big, .veryBig, .huge]
        guard let index = order.firstIndex(of: windowWidth) else { return }

        let nextIndex = index + (increase ? 1 : -1)
        if order.indices.contains(nextIndex) {
            windowWidth = order[nextIndex]
        }
    }

    private var windowWidthLabel: String {
        switch windowWidth {
        case .tiny:
            return String(localized: "window_size_tiny")
        case .normal:
            return String(localized: "window_size_normal")
        case .big:
            return String(localized: "window_size_big")
        case .veryBig:
            return String(localized: "window_size_verybig")
        case .huge:
            return String(localized: "window_size_huge")
        }
    }

    private func untoggleShowOptions() {
        showSystemOptions = false
        showInterfaceOptions = false
        showInfoOptions = false
        showOthersOptions = false
        showContextMenuOptions = false
        showHeritageOptions = false
    }

    private func manageShowOptions(binding: Binding<Bool>) {
        if binding.wrappedValue {
            binding.wrappedValue.toggle()
        } else {
            untoggleShowOptions()
            binding.wrappedValue = true
        }
    }

    private func toggleLoginItem(enabled: Bool) {
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
        let version = ProcessInfo.processInfo.operatingSystemVersion

        ZStack {
            Image(systemName: "gear")
                .font(.system(size: 350))
                .opacity(0.03)
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MenuBarUSB")
                            .font(.title2)
                            .bold()
                        Text(
                            String(
                                format: NSLocalizedString("version", comment: "APP VERSION"),
                                "\(Utils.App.appVersion) - OS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
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

                HStack(alignment: .center) {
                    categoryButton(toggle: $showSystemOptions, label: "system_category")
                    categoryButton(toggle: $showInterfaceOptions, label: "ui_category")
                    categoryButton(toggle: $showInfoOptions, label: "usb_category")
                    categoryButton(toggle: $showContextMenuOptions, label: "context_menu_category")
                    categoryButton(toggle: $showHeritageOptions, label: "heritage_category")
                    categoryButton(toggle: $showOthersOptions, label: "others_category")
                }

                VStack(alignment: .leading, spacing: 6) {
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
                        ToggleRow(
                            label: String(localized: "play_hardware_sound"),
                            description: String(localized: "play_hardware_sound_description"),
                            binding: $playHardwareSound,
                            activeRowID: $activeRowID,
                            incompatibilities: nil,
                            onToggle: { _ in }
                        )
                        HStack {
                            Button {
                                hardwareSound = ""
                                playHardwareSound = false
                            } label: {
                                Image(systemName: "trash")
                            }
                            .disabled(hardwareSound.isEmpty)
                            Menu {
                                ForEach(HardwareSound.all, id: \.uniqueId) { sound in
                                    Button(LocalizedStringKey(sound.titleKey)) {
                                        hardwareSound = sound.uniqueId
                                    }
                                }
                            } label: {
                                let sound = HardwareSound[hardwareSound]
                                let title = LocalizedStringKey(sound?.titleKey ?? "none_default")
                                Text(title)
                            }
                            if hardwareSound != "" {
                                Button {
                                    let sound = HardwareSound[hardwareSound]
                                    Utils.System.playSound(sound?.connect)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                        Utils.System.playSound(sound?.disconnect)
                                    }
                                } label: {
                                    Image(systemName: "play")
                                }
                            }
                        }
                        .disabled(!playHardwareSound)
                    }

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
                            label: String(localized: "show_scrollbar"),
                            description: String(localized: "show_scrollbar_description"),
                            binding: $showScrollBar,
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
                            label: String(localized: "index_indicator"),
                            description: String(localized: "index_indicator_description"),
                            binding: $indexIndicator,
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
                            Text("list_width")
                            Button {
                                setWindowWidth(increase: false)
                            } label: {
                                Image(systemName: "minus")
                                    .frame(width: 14, height: 14)
                            }
                            .disabled(windowWidth == .tiny)

                            Button {
                                setWindowWidth(increase: true)
                            } label: {
                                Image(systemName: "plus")
                                    .frame(width: 14, height: 14)
                            }
                            .disabled(windowWidth == .huge)

                            Text(windowWidthLabel)
                                .font(.footnote)
                        }
                        .padding(.vertical, 7)
                    }

                    if showInfoOptions {
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

                        HStack {
                            Button("delete_device_history") {
                                tryingToDeleteDeviceHistory = true
                            }
                            .disabled(tryingToDeleteDeviceHistory || CSM.Stored.devices.isEmpty)
                            .help("(\(CSM.Stored.devices.count))")

                            if tryingToDeleteDeviceHistory {
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
                        .padding(.vertical, 10)

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
                    }

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
                            label: String(localized: "disable_context_menu_heritage"),
                            description: String(localized: "disable_context_menu_heritage_description"),
                            binding: $disableContextMenuHeritage,
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

                    if showHeritageOptions {
                        ToggleRow(
                            label: String(localized: "disable_inheritance_layout"),
                            description: String(localized: "disable_inheritance_layout_description"),
                            binding: $disableInheritanceLayout,
                            activeRowID: $activeRowID,
                            incompatibilities: nil,
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
                            CSM.Heritage.clear()
                        } label: {
                            Label("clear_all_inheritances", systemImage: "trash")
                        }
                        .disabled(CSM.Heritage.$items.count <= 0)
                    }

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
                            label: String(localized: "show_toolbar"),
                            description: String(localized: "show_toolbar_description"),
                            binding: $listToolBar,
                            activeRowID: $activeRowID,
                            incompatibilities: nil,
                            onToggle: { _ in }
                        )
                        ToggleRow(
                            label: String(localized: "ethernet_connected_icon"),
                            description: String(localized: "ethernet_connected_icon_description"),
                            binding: $showEthernet,
                            activeRowID: $activeRowID,
                            incompatibilities: nil,
                            onToggle: { value in
                                if value == true {
                                    Utils.App.restart()
                                }
                            }
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
                            label: String(localized: "hide_check_update"),
                            description: String(localized: "hide_check_update_description"),
                            binding: $hideUpdate,
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
                                Utils.System.hapticFeedback()
                            }
                            .padding(4)
                    }
                    Spacer()
                    Button("close") {
                        dismiss()
                    }
                }
            }
        }
        .padding(10)
        .frame(minWidth: 700, minHeight: 580)
        .appBackground(reduceTransparency)
    }
}
