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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) var openURL
    @EnvironmentObject var manager: USBDeviceManager

    @State private var showMessage: Bool = false

    @State private var activeRowID: UUID? = nil

    @State private var isPlayingSound = false
    @State private var tryingToResetSettings = false
    @State private var tryingToDeleteDeviceHistory = false
    @State private var checkingUpdate = false
    @State private var updateAvailable = false
    @State private var latestVersion: String = ""
    @State private var releaseURL: URL? = nil

    @State private var hoveringInfo: Bool = false
    @State private var isBitcoin = true

    @State private var showSystemOptions = false
    @State private var showInterfaceOptions = false
    @State private var showInfoOptions = false
    @State private var showContextMenuOptions = false
    @State private var showHeritageOptions = false
    @State private var showOthersOptions = false
    @State private var showDonateOptions = false
    @State private var showStorageOptions = false

    @AS(Key.launchAtLogin) private var launchAtLogin = false
    @AS(Key.convertHexa) private var convertHexa = false
    @AS(Key.longList) private var longList = false
    @AS(Key.hideTechInfo) private var hideTechInfo = false
    @AS(Key.showPortMax) private var showPortMax = false
    @AS(Key.hideDonate) private var hideDonate = false
    @AS(Key.powerSourceInfo) private var powerSourceInfo = false
    @AS(Key.storeConnectionLogs) private var storeConnectionLogs = false
    @AS(Key.contextMenuCopyAll) private var contextMenuCopyAll = false
    @AS(Key.renamedIndicator) private var renamedIndicator = false
    @AS(Key.camouflagedIndicator) private var camouflagedIndicator = false
    @AS(Key.hideMenubarIcon) private var hideMenubarIcon = false
    @AS(Key.hideCount) private var hideCount = false
    @AS(Key.listToolBar) private var listToolBar = false
    @AS(Key.showNotifications) private var showNotifications = false
    @AS(Key.newVersionNotification) private var newVersionNotification = false
    @AS(Key.reduceTransparency) private var reduceTransparency = false
    @AS(Key.disableNotifCooldown) private var disableNotifCooldown = false
    @AS(Key.hardwareSound) private var hardwareSound: String = ""
    @AS(Key.playHardwareSound) private var playHardwareSound: Bool = false
    @AS(Key.disableHaptic) private var disableHaptic = false
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
    @AS(Key.bigNames) private var bigNames = false
    @AS(Key.mouseHoverInfo) private var mouseHoverInfo = false
    @AS(Key.hidePinIndicator) private var hidePinIndicator = false
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
    
    private func openLinkedinProfile() {
        if let url = URL(string: Utils.Miscellaneous.linkedinUrl) {
            openURL(url)
        }
    }
    
    private var updateButtonLabel: String {
        
        if updateAvailable {
            return "\("download".localized) (v\(latestVersion))";
        }
        
        if checkingUpdate {
            return "looking_for_updates"
        } else if latestVersion.isEmpty {
            return "check_for_updates"
        } else {
            return "updated"
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
            return "window_size_tiny"
        case .normal:
            return "window_size_normal"
        case .big:
            return "window_size_big"
        case .veryBig:
            return "window_size_verybig"
        case .huge:
            return "window_size_huge"
        }
    }

    private func untoggleShowOptions() {
        showSystemOptions = false
        showInterfaceOptions = false
        showInfoOptions = false
        showOthersOptions = false
        showContextMenuOptions = false
        showStorageOptions = false
        showHeritageOptions = false
        showDonateOptions = false
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

    private func updateButtonAction() {
        
        if updateAvailable, let releaseURL {
            openURL(releaseURL)
            return
        }
        
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
                }
            }
        }.resume()
    }

    var body: some View {
        let version = ProcessInfo.processInfo.operatingSystemVersion

        ZStack {
            if #available(macOS 14.0, *) {
                Image(systemName: "gear")
                    .font(.system(size: 350))
                    .opacity(0.03)
            }
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
                                "\("open_download_page".localized) (v\(latestVersion))",
                                destination: releaseURL
                            )
                            .buttonStyle(.borderedProminent)
                        }
                    }

                    if !updateAvailable {
                        HStack {
                            if !hideUpdate {
                                Button(updateButtonLabel.localized) {
                                    updateButtonAction()
                                }
                                .foregroundStyle(updateAvailable ? AssetColors.update : .primary)
                                .contextMenu {
                                    Button {
                                        hideUpdate = true
                                    } label: {
                                        Label("hide_button", systemImage: "eye.slash")
                                    }
                                }
                            }
                            
                            if !hideDonate && !hideUpdate {
                                Text("|")
                                    .padding(.horizontal, 5)
                                    .opacity(0.3)
                            }

                            if !hideDonate {

                                Button {
                                    if showDonateOptions {
                                        showDonateOptions = false
                                    } else {
                                        untoggleShowOptions()
                                        showDonateOptions = true
                                    }
                                } label: {
                                    Text("donate")
                                }
                                .contextMenu {
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

                Divider()

                HStack(alignment: .center) {
                    categoryButton(toggle: $showSystemOptions, label: "system_category")
                    categoryButton(toggle: $showInterfaceOptions, label: "ui_category")
                    categoryButton(toggle: $showInfoOptions, label: "usb_category")
                    categoryButton(toggle: $showContextMenuOptions, label: "rmb")
                    categoryButton(toggle: $showHeritageOptions, label: "heritage_category")
                    categoryButton(toggle: $showOthersOptions, label: "others_category")
                    categoryButton(toggle: $showStorageOptions, label: "storage_category")
                }

                VStack(alignment: .leading, spacing: 6) {
                    if showSystemOptions {
                        ToggleRow(
                            label: "open_on_startup",
                            description: "open_on_startup_description",
                            binding: $launchAtLogin,
                            activeRowID: $activeRowID,
                            incompatibilities: nil,
                            onToggle: { value in
                                toggleLoginItem(enabled: value)
                            }
                        )
                        ToggleRow(
                            label: "new_version_notification",
                            description: "new_version_notification_description",
                            binding: $newVersionNotification,
                            activeRowID: $activeRowID,
                            incompatibilities: nil,
                            onToggle: { _ in }
                        )
                        ToggleRow(
                            label: "show_notification",
                            description: "show_notification_description",
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
                            label: "disable_notification_cooldown",
                            description: "disable_notification_cooldown_description",
                            binding: $disableNotifCooldown,
                            activeRowID: $activeRowID,
                            incompatibilities: nil,
                            disabled: showNotifications == false,
                            onToggle: { _ in }
                        )
                        ToggleRow(
                            label: "play_hardware_sound",
                            description: "play_hardware_sound_description",
                            binding: $playHardwareSound,
                            activeRowID: $activeRowID,
                            incompatibilities: nil,
                            onToggle: { _ in }
                        )
                        HStack {
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
                            .contextMenu {
                                Button("undo_all_devices_sound_associations") {
                                    CSM.SoundDevices.clear()
                                    Utils.App.restart()
                                }
                            }

                            if hardwareSound != "" {
                                Button {
                                    isPlayingSound = true
                                    let sound = HardwareSound[hardwareSound]
                                    Utils.System.playSound(sound?.connect)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                        Utils.System.playSound(sound?.disconnect)
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                                        isPlayingSound = false
                                    }
                                } label: {
                                    Image(systemName: "play.fill")
                                }
                                .buttonStyle(.borderless)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: 290)
                        .disabled(isPlayingSound)
                        .opacity(playHardwareSound ? 1.0 : 0.1)
                    }

                    if showInterfaceOptions {
                        ToggleRow(
                            label: "hide_technical_info",
                            description: "hide_technical_info_description",
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
                            label: "mouse_hover_info",
                            description: "mouse_hover_info_description",
                            binding: $mouseHoverInfo,
                            activeRowID: $activeRowID,
                            incompatibilities: nil,
                            disabled: !hideTechInfo,
                            onToggle: { _ in }
                        )
                        ToggleRow(
                            label: "hide_secondary_info",
                            description: "hide_secondary_info_description",
                            binding: $hideSecondaryInfo,
                            activeRowID: $activeRowID,
                            incompatibilities: nil,
                            onToggle: { _ in }
                        )
                        ToggleRow(
                            label: "show_scrollbar",
                            description: "show_scrollbar_description",
                            binding: $showScrollBar,
                            activeRowID: $activeRowID,
                            incompatibilities: nil,
                            onToggle: { _ in }
                        )
                        ToggleRow(
                            label: "long_list",
                            description: "long_list_description",
                            binding: $longList,
                            activeRowID: $activeRowID,
                            incompatibilities: nil,
                            onToggle: { _ in }
                        )
                        ToggleRow(
                            label: "big_names",
                            description: "big_names_description",
                            binding: $bigNames,
                            activeRowID: $activeRowID,
                            incompatibilities: nil,
                            onToggle: { _ in }
                        )
                        ToggleRow(
                            label: "show_previously_connected",
                            description: "show_previously_connected_description",
                            binding: $storeDevices,
                            activeRowID: $activeRowID,
                            incompatibilities: nil,
                            onToggle: { _ in }
                        )

                        HStack {
                            Text("list_width")
                            Button {
                                setWindowWidth(increase: false)
                                manager.refresh()
                            } label: {
                                Image(systemName: "minus")
                                    .frame(width: 14, height: 14)
                            }
                            .disabled(windowWidth == .normal)

                            Button {
                                setWindowWidth(increase: true)
                                manager.refresh()
                            } label: {
                                Image(systemName: "plus")
                                    .frame(width: 14, height: 14)
                            }
                            .disabled(windowWidth == .veryBig)

                            Text(windowWidthLabel.localized)
                                .font(.footnote)
                        }
                        .padding(.top, 7)
                    }

                    if showInfoOptions {
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
                            label: "convert_hexa",
                            description: "convert_hexa_description",
                            binding: $convertHexa,
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

                    if showContextMenuOptions {
                        Text("rmb_explanation")
                            .font(.title2)
                            .italic()
                            .padding(.vertical)
                            .opacity(0.8)

                        ToggleRow(
                            label: "disable_context_menu_search",
                            description: "disable_context_menu_search_description",
                            binding: $disableContextMenuSearch,
                            activeRowID: $activeRowID,
                            incompatibilities: nil,
                            onToggle: { _ in }
                        )
                        ToggleRow(
                            label: "disable_context_menu_heritage",
                            description: "disable_context_menu_heritage_description",
                            binding: $disableContextMenuHeritage,
                            activeRowID: $activeRowID,
                            incompatibilities: nil,
                            onToggle: { _ in }
                        )
                        ToggleRow(
                            label: "allow_copying_individual",
                            description: "allow_copying_individual_description",
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

                    if showOthersOptions {
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
                    
                    if showStorageOptions {
                        
                        StorageButton(type: .pinned) {
                            CSM.Pin.clear()
                            manager.refresh()
                        }
                        
                        StorageButton(type: .renamed) {
                            CSM.Renamed.clear()
                            manager.refresh()
                        }
                        
                        StorageButton(type: .camouflaged) {
                            CSM.Camouflaged.clear()
                            manager.refresh()
                        }
                        
                        StorageButton(type: .heritage) {
                            CSM.Heritage.clear()
                            manager.refresh()
                        }
                        
                        StorageButton(type: .soundAssociation) {
                            CSM.SoundDevices.clear()
                            manager.refresh()
                        }
                        
                        StorageButton(type: .sound) {
                            CSM.Sound.clear()
                            manager.refresh()
                        }
                        
                        StorageButton(type: .stored) {
                            CSM.Stored.clear()
                            manager.refresh()
                        }
                        
                        StorageButton(type: .log) {
                            CSM.ConnectionLog.clear()
                            manager.refresh()
                        }
                        
                        Spacer()
                            .frame(height: 8)
                        
                        HStack {
                            
                            Button("restore_default_settings") {
                                tryingToResetSettings = true
                            }
                            .disabled(tryingToResetSettings)
                            
                            if tryingToResetSettings {
                                HStack(spacing: 12) {
                                    Text("are_you_sure")
                                        .bold()
                                        .foregroundStyle(.red)
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

                    if showDonateOptions {
                        let currentAddress = isBitcoin ? Utils.Miscellaneous.btcAddress : Utils.Miscellaneous.ltcAddress
                        let currentSymbol = isBitcoin ? "bitcoinsign.circle.fill" : "l.circle.fill"
                        let currentColor: Color = isBitcoin ? .orange : AssetColors.ltcCoin
                        let email = Utils.Miscellaneous.contactEmail

                        HStack(spacing: 20) {
                            Utils.Miscellaneous.QRCodeView(text: currentAddress)
                                .frame(width: 230, height: 230)
                                .padding()
                                .contextMenu {
                                    Button { Utils.System.copyToClipboard(currentAddress) } label: {
                                        Label("copy_crypto_address", systemImage: "square.on.square")
                                    }

                                    Button { Utils.System.copyToClipboard(email) } label: {
                                        Label("copy_email", systemImage: "square.on.square")
                                    }
                                }

                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Image(systemName: currentSymbol)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 18, height: 18)
                                        .foregroundColor(currentColor)

                                    Text(isBitcoin ? "bitcoin_on_chain_transfer" : "litecoin_on_chain_transfer")
                                        .font(.headline)
                                        .bold()
                                }

                                VStack(alignment: .leading, spacing: 10) {
                                    Text(currentAddress)
                                        .font(.subheadline)
                                        .contextMenu {
                                            Button { Utils.System.copyToClipboard(currentAddress) } label: {
                                                Label("copy", systemImage: "square.on.square")
                                            }
                                        }

                                    Text(String(format: NSLocalizedString("contact", comment: "EMAIL"), email))
                                        .font(.subheadline)
                                        .contextMenu {
                                            Button { Utils.System.copyToClipboard(email) } label: {
                                                Label("copy_email", systemImage: "square.on.square")
                                            }
                                        }
                                }
                                
                                Text(String(format: NSLocalizedString("linkedin_profile", comment: "LINKEDIN"), Utils.Miscellaneous.linkedinProfile))
                                    .font(.subheadline)
                                    .contextMenu {
                                        Button("copy_profile_url") {
                                            Utils.System.copyToClipboard(Utils.Miscellaneous.linkedinUrl)
                                        }
                                        Button("open_linkedin_profile") {
                                            openLinkedinProfile()
                                        }
                                    }

                                Button(action: { isBitcoin.toggle() }) {
                                    Text(isBitcoin ? "show_ltc_address" : "show_btc_address")
                                }
                                .padding(.top, 4)
                            }
                            .padding(.vertical)
                        }
                        .padding(.horizontal)
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
