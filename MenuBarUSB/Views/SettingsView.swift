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

    @State private var disableButtonsRelatedToSound: Bool = false
    @State private var creatingNewAudioSet: Bool = false
    @State private var audioSetConnectedPath: String = ""
    @State private var audioSetDisconnectedPath: String = ""
    @State private var selectedDeviceToCamouflage: USBDeviceWrapper?
    @State private var selectedDeviceToRename: USBDeviceWrapper?
    @State private var inputText: String = ""
    @State private var textFieldFocused: Bool = false
    @State private var activeRowID: UUID? = nil

    @State private var resetSettingsPress: Int = 0
    @State private var tryingToDeleteDeviceHistory = false
    @State private var checkingUpdate = false
    @State private var updateAvailable = false
    @State private var latestVersion: String = ""
    @State private var releaseURL: URL? = nil

    @AS(Key.settingsCategory) private var category: SettingsCategory = .system

    @AS(Key.launchAtLogin) private var launchAtLogin = false
    @AS(Key.convertHexa) private var convertHexa = false
    @AS(Key.longList) private var longList = false
    @AS(Key.hideTechInfo) private var hideTechInfo = false
    @AS(Key.showPortMax) private var showPortMax = false
    @AS(Key.renamedIndicator) private var renamedIndicator = false
    @AS(Key.camouflagedIndicator) private var camouflagedIndicator = false
    @AS(Key.showNotifications) private var showNotifications = false
    @AS(Key.reduceTransparency) private var reduceTransparency = false
    @AS(Key.disableNotifCooldown) private var disableNotifCooldown = false
    @AS(Key.disableInheritanceLayout) private var disableInheritanceLayout = false
    @AS(Key.powerSourceInfo) private var powerSourceInfo = false
    @AS(Key.forceDarkMode) private var forceDarkMode = false
    @AS(Key.forceLightMode) private var forceLightMode = false
    @AS(Key.increasedIndentationGap) private var increasedIndentationGap = false
    @AS(Key.hideSecondaryInfo) private var hideSecondaryInfo = false
    @AS(Key.hideUpdate) private var hideUpdate = false
    @AS(Key.hideDonate) private var hideDonate = false
    @AS(Key.noTextButtons) private var noTextButtons = false
    @AS(Key.hideCount) private var hideCount = false
    @AS(Key.numberRepresentation) private var numberRepresentation: NumberRepresentation = .base10
    @AS(Key.listToolBar) private var listToolBar = false
    @AS(Key.macBarIcon) private var macBarIcon: String = "cable.connector"
    @AS(Key.hideMenubarIcon) private var hideMenubarIcon = false
    @AS(Key.restartButton) private var restartButton = false
    @AS(Key.mouseHoverInfo) private var mouseHoverInfo = false
    @AS(Key.profilerButton) private var profilerButton = false
    @AS(Key.windowWidth) private var windowWidth: WindowWidth = .normal
    @AS(Key.hardwareSound) private var hardwareSound: String = ""
    @AS(Key.playHardwareSound) private var playHardwareSound: Bool = false
    @AS(Key.disableContextMenuSearch) private var disableContextMenuSearch = false
    @AS(Key.disableContextMenuHeritage) private var disableContextMenuHeritage = false
    @AS(Key.showEthernet) private var showEthernet = false
    @AS(Key.internetMonitoring) private var internetMonitoring = false
    @AS(Key.disableHaptic) private var disableHaptic = false
    @AS(Key.trafficButton) private var trafficButton = false
    @AS(Key.disableTrafficButtonLabel) private var disableTrafficButtonLabel = false
    @AS(Key.newVersionNotification) private var newVersionNotification = false
    @AS(Key.contextMenuCopyAll) private var contextMenuCopyAll = false
    @AS(Key.fastMonitor) private var fastMonitor = false
    @AS(Key.showScrollBar) private var showScrollBar = false
    @AS(Key.indexIndicator) private var indexIndicator = false
    @AS(Key.storeDevices) private var storeDevices = false
    @AS(Key.storedIndicator) private var storedIndicator = false
    @AS(Key.forceEnglish) private var forceEnglish = false
    @AS(Key.searchEngine) private var searchEngine: SearchEngine = .google

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

    private func saveToStorageAndGetPath(_ path: String) -> String {
        let fileManager = FileManager.default
        let sourceURL = URL(fileURLWithPath: path)

        let appSupport = try! fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let destination = appSupport.appendingPathComponent(sourceURL.lastPathComponent)

        if fileManager.fileExists(atPath: destination.path) {
            try? fileManager.removeItem(at: destination)
        }

        try? fileManager.copyItem(at: sourceURL, to: destination)
        return destination.path
    }

    private func pickFile(completion: @escaping (String?) -> Void) {
        let dialog = NSOpenPanel()
        dialog.title = "select_file"
        dialog.allowsMultipleSelection = false
        dialog.allowedContentTypes = [.mp3]
        dialog.canChooseDirectories = true
        dialog.canChooseFiles = true
        dialog.canChooseDirectories = false

        if dialog.runModal() == .OK {
            completion(dialog.url?.path)
        } else {
            completion(nil)
        }
    }

    private var isCustomSoundSetSelected: Bool {
        return CSM.Sound[hardwareSound] != nil
    }

    private func resetAudioSetVariables() {
        inputText = ""
        textFieldFocused = false
        audioSetConnectedPath = ""
        audioSetDisconnectedPath = ""
        creatingNewAudioSet = false
    }

    private func confirmNewAudioSet() {
        defer { resetAudioSetVariables() }
        let connect = saveToStorageAndGetPath(audioSetConnectedPath)
        let disconnect = saveToStorageAndGetPath(audioSetDisconnectedPath)
        let item = HardwareSound(
            uniqueId: UUID().uuidString,
            titleKey: inputText,
            connect: connect,
            disconnect: disconnect
        )
        CSM.Sound.add(item)
    }

    private func confirmRenameDevice() {
        let uniqueId = selectedDeviceToRename!.item.uniqueId
        if inputText.isEmpty {
            CSM.Renamed.remove(withId: uniqueId)
        } else {
            CSM.Renamed.add(selectedDeviceToRename?.item.uniqueId, inputText)
        }
        inputText = ""
        selectedDeviceToRename = nil
        showRenameDevices = false
        manager.refresh()
    }

    private func confirmCamouflageDevice() {
        CSM.Camouflaged.add(withId: selectedDeviceToCamouflage?.item.uniqueId)
        selectedDeviceToCamouflage = nil
        showCamouflagedDevices = false
        manager.refresh()
    }

    private func testHardwareSound(_ seconds: Double = 1.2) {
        let sec = isCustomSoundSetSelected ? seconds * 2.5 : seconds
        disableButtonsRelatedToSound = true
        let sound = HardwareSound[hardwareSound]
        Utils.System.playSound(sound?.connect)
        DispatchQueue.main.asyncAfter(deadline: .now() + sec) {
            Utils.System.playSound(sound?.disconnect)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + sec * 2) {
            disableButtonsRelatedToSound = false
        }
    }
    
    private func playOnlyOneSound(for hardwareSound: String, connect: Bool) {
        playHardwareSound = false
        defer {
            let time: Double = isCustomSoundSetSelected ? 2.5 : 1.5
            DispatchQueue.main.asyncAfter(deadline: .now() + time) {
                playHardwareSound = true
            }
        }
        let sound = HardwareSound[hardwareSound]
        if connect {
            Utils.System.playSound(sound?.connect)
        } else {
            Utils.System.playSound(sound?.disconnect)
        }
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

    private func setWindowWidth(increase: Bool) {
        let order: [WindowWidth] = [.tiny, .normal, .big, .veryBig, .huge]
        guard let index = order.firstIndex(of: windowWidth) else { return }

        let nextIndex = index + (increase ? 1 : -1)
        if order.indices.contains(nextIndex) {
            windowWidth = order[nextIndex]
        }
    }

    private var windowWidthLabel: String {
        var width = ""
        switch windowWidth {
        case .tiny:
            width = "window_size_tiny"
        case .normal:
            width = "window_size_normal"
        case .big:
            width = "window_size_big"
        case .veryBig:
            width = "window_size_verybig"
        case .huge:
            width = "window_size_huge"
        }
        return width.localized
    }

    private func resetAppSettings() {
        Utils.App.deleteStorageData()
        resetSettingsPress = 0
        Utils.System.playSound("Bottle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            Utils.App.restart()
        }
    }

    private func undoAllRenamedDevices() {
        CSM.Renamed.clear()
        showRenameDevices = false
        manager.refresh()
    }

    private func undoAllCamouflagedDevices() {
        CSM.Camouflaged.clear()
        showCamouflagedDevices = false
        manager.refresh()
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

    private var disableConfirmNewAudioSet: Bool {
        let path1 = audioSetConnectedPath == ""
        let path2 = audioSetDisconnectedPath == ""
        let hasTitle = inputText == ""
        return path1 || path2 || hasTitle
    }

    private func deleteHardwareSound(for sound: HardwareSound?) {
        CSM.Sound.remove(withId: sound?.uniqueId ?? "")
        hardwareSound = ""
    }

    private func pickAudioFilePath(connect: Bool) {
        pickFile { path in
            if connect {
                audioSetConnectedPath = path ?? ""
            } else {
                audioSetDisconnectedPath = path ?? ""
            }
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
                            "\("open_download_page".localized) (v\(latestVersion))",
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
                    let off = anyBottomOptionInUse
                    CategoryButton(category: .system, label: "system_category", image: "settings_general", binding: $category, disabled: off)
                    CategoryButton(category: .icon, label: "icon_category", image: "settings_icon", binding: $category, disabled: off)
                    CategoryButton(category: .interface, label: "ui_category", image: "settings_interface", binding: $category, disabled: off)
                    CategoryButton(category: .usb, label: "usb_category", image: "settings_info", binding: $category, disabled: off)
                    CategoryButton(category: .contextMenu, label: "context_menu_category", image: "settings_contextmenu", binding: $category, disabled: off)
                    CategoryButton(category: .ethernet, label: "ethernet_category", image: "settings_ethernet", binding: $category, disabled: off)
                    CategoryButton(category: .heritage, label: "heritage_category", image: "settings_heritage", binding: $category, disabled: off)
                    CategoryButton(category: .others, label: "others_category", image: "settings_others", binding: $category, disabled: off) {
                        resetSettingsPress = 0
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5)

                Text(LocalizedStringKey(category.rawValue))
                    .font(.title)
                    .padding(.vertical, 10)

                if category == .system {
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
                        label: "reduce_transparency",
                        description: "reduce_transparency_description",
                        binding: $reduceTransparency,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        disabled: forceDarkMode || forceLightMode,
                        onToggle: { _ in }
                    )
                    ToggleRow(
                        label: "force_dark_mode",
                        description: "force_dark_mode_description",
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
                        label: "force_light_mode",
                        description: "force_light_mode_description",
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
                            if value {
                                Utils.System.requestNotificationPermission()
                            } else {
                                disableNotifCooldown = false
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
                        disabled: disableButtonsRelatedToSound,
                        onToggle: { _ in }
                    )
                    HStack {
                        if isCustomSoundSetSelected {
                            Button {
                                deleteHardwareSound(for: CSM.Sound[hardwareSound])
                            } label: {
                                Image(systemName: "trash")
                            }
                            .help("delete")
                        }
                        Menu {
                            ForEach(HardwareSound.all, id: \.uniqueId) { sound in
                                Button {
                                    hardwareSound = sound.uniqueId
                                } label: {
                                    Label(LocalizedStringKey(sound.titleKey), systemImage: "speaker.wave.3")
                                }
                            }
                            Divider()
                            Button {
                                creatingNewAudioSet.toggle()
                            } label: {
                                Label("new_set", systemImage: "plus")
                            }
                        } label: {
                            let sound = HardwareSound[hardwareSound]
                            let title = LocalizedStringKey(sound?.titleKey ?? "none_default")
                            Text(title)
                        }
                        .contextMenu {
                            let amount = CSM.SoundDevices.items.count
                            let text = "\("undo_all_devices_sound_associations".localized) (\(amount))"
                            Button(amount > 0 ? text : "no_custom_association_to_undo".localized) {
                                CSM.SoundDevices.clear()
                                manager.refresh()
                            }
                            .disabled(amount <= 0)
                        }

                        if hardwareSound != "" {
                            Button {
                                testHardwareSound()
                            } label: {
                                Image(systemName: "play")
                            }
                            .contextMenu {
                                Button("play_only_connect") {
                                    playOnlyOneSound(for: hardwareSound, connect: true)
                                }
                                
                                Button("play_only_disconnect") {
                                    playOnlyOneSound(for: hardwareSound, connect: false)
                                }
                            }
                        }
                        Spacer()
                    }
                    .frame(maxWidth: 280)
                    .disabled(!playHardwareSound)
                    .opacity(playHardwareSound ? 1.0 : 0.3)
                    .disabled(disableButtonsRelatedToSound)

                    if creatingNewAudioSet {
                        CustomTextField(
                            text: $inputText,
                            placeholder: "title",
                            maxLength: 12,
                            isFocused: $textFieldFocused
                        )
                        .frame(width: 190)

                        HStack {
                            Button {
                                pickAudioFilePath(connect: true)
                            } label: {
                                Image(systemName: audioSetConnectedPath.isEmpty ? "document" : "checkmark")
                            }
                            Text(audioSetConnectedPath.isEmpty ? "connected_audio_file".localized : audioSetConnectedPath)
                                .lineLimit(1)
                        }

                        HStack {
                            Button {
                                pickAudioFilePath(connect: false)
                            } label: {
                                Image(systemName: audioSetDisconnectedPath.isEmpty ? "document" : "checkmark")
                            }
                            Text(audioSetDisconnectedPath.isEmpty ? "disconnected_audio_file".localized : audioSetDisconnectedPath)
                                .lineLimit(1)
                        }

                        HStack {
                            Button("cancel") {
                                resetAudioSetVariables()
                            }
                            Button("create") {
                                confirmNewAudioSet()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(disableConfirmNewAudioSet)
                        }
                    }
                }

                if category == .icon {
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

                if category == .interface {
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
                        label: "show_previously_connected",
                        description: "show_previously_connected_description",
                        binding: $storeDevices,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
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

                    Button("delete_device_history") {
                        tryingToDeleteDeviceHistory = true
                    }
                    .disabled(tryingToDeleteDeviceHistory || CSM.Stored.devices.isEmpty)
                    .help("(\(CSM.Stored.devices.count))")
                    .padding(.vertical, 5)

                    if tryingToDeleteDeviceHistory {
                        HStack(spacing: 6) {
                            Text("are_you_sure")
                            Button("no") {
                                tryingToDeleteDeviceHistory = false
                            }
                            Button("yes_confirm") {
                                CSM.Stored.clear()
                                tryingToDeleteDeviceHistory = false
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }

                if category == .usb {
                    if Utils.System.isMacbook {
                        ToggleRow(
                            label: "show_charger",
                            description: "show_charger_description",
                            binding: $powerSourceInfo,
                            activeRowID: $activeRowID,
                            incompatibilities: nil,
                            onToggle: { _ in manager.refresh() }
                        )
                    }
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
                            CSM.Renamed.clear()
                            manager.refresh()
                        } label: {
                            Label("undo_all", systemImage: "trash")
                        }
                        .disabled(CSM.Renamed.devices.isEmpty)
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
                            CSM.Camouflaged.clear()
                            manager.refresh()
                        } label: {
                            Label("undo_all", systemImage: "trash")
                        }
                        .disabled(CSM.Camouflaged.devices.isEmpty)
                    }
                }

                if category == .contextMenu {
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
                        .frame(width: 130)
                        .disabled(disableContextMenuSearch)
                        .padding(.vertical, 5)
                    }
                }

                if category == .ethernet {
                    ToggleRow(
                        label: "ethernet_connected_icon",
                        description: "ethernet_connected_icon_description",
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
                        label: "internet_monitoring_icon",
                        description: "internet_monitoring_icon_description",
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
                        label: "stop_traffic_monitor_button",
                        description: "stop_traffic_monitor_button_description",
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
                        label: "stop_traffic_monitor_button_disable_status",
                        description: "stop_traffic_monitor_button_disable_status_description",
                        binding: $disableTrafficButtonLabel,
                        activeRowID: $activeRowID,
                        incompatibilities: [profilerButton, restartButton],
                        disabled: !showEthernet || !internetMonitoring,
                        onToggle: { _ in }
                    )
                    ToggleRow(
                        label: "fast_traffic_monitor",
                        description: "fast_traffic_monitor_description",
                        binding: $fastMonitor,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        disabled: !internetMonitoring,
                        onToggle: { _ in }
                    )
                }

                if category == .heritage {
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

                if category == .others {
                    if Locale.current.language.languageCode?.identifier != "en" {
                        ToggleRow(
                            label: "force_english",
                            description: "force_english_description",
                            binding: $forceEnglish,
                            activeRowID: $activeRowID,
                            incompatibilities: nil,
                            willRestart: true,
                            onToggle: { _ in Utils.App.restart() }
                        )
                    }
                    ToggleRow(
                        label: "show_toolbar",
                        description: "show_toolbar_description",
                        binding: $listToolBar,
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
                        label: "no_text_buttons",
                        description: "no_text_buttons_description",
                        binding: $noTextButtons,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: { _ in }
                    )
                    ToggleRow(
                        label: "restart_button",
                        description: "restart_button_description",
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
                        label: "profiler_shortcut",
                        description: "profiler_shortcut_description",
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

                    HStack {
                        Text("window_width")
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
                    if category == .others {
                        Button("restore_default_settings") {
                            resetSettingsPress += 1
                            if resetSettingsPress == 5 {
                                resetAppSettings()
                            }
                        }

                        if resetSettingsPress > 0 {
                            Text("(\(resetSettingsPress)/5)")
                                .font(.footnote)
                        }
                    }

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
                                let renamedDevice = CSM.Renamed.devices.first {
                                    $0.deviceId == device.item.uniqueId
                                }
                                let buttonLabel = renamedDevice?.name ?? device.item.name
                                Button(buttonLabel) {
                                    selectedDeviceToCamouflage = device
                                }
                            }
                        } label: {
                            Text(selectedDeviceToCamouflage?.item.name ?? "device".localized)
                        }

                        if selectedDeviceToCamouflage != nil {
                            if (CSM.Heritage.devices.contains {
                                $0.inheritsFrom == selectedDeviceToCamouflage!.item.uniqueId
                            }) {
                                Text("cant_hide_heir")
                                    .font(.subheadline)
                            } else {
                                Button("confirm") {
                                    confirmCamouflageDevice()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }

                        if selectedDeviceToCamouflage == nil && !CSM.Camouflaged.devices.isEmpty {
                            Button("undo_all") {
                                undoAllCamouflagedDevices()
                            }
                        }

                        Spacer()
                    }
                }

                if showRenameDevices {
                    HStack(spacing: 12) {
                        Menu {
                            ForEach(manager.devices, id: \.self) { device in
                                let renamedDevice = CSM.Renamed.devices.first {
                                    $0.deviceId == device.item.uniqueId
                                }
                                let buttonLabel = renamedDevice?.name ?? device.item.name
                                Button(buttonLabel) {
                                    inputText = ""
                                    selectedDeviceToRename = device
                                }
                            }
                        } label: {
                            Text(selectedDeviceToRename?.item.name ?? "device".localized)
                        }

                        if selectedDeviceToRename != nil {
                            CustomTextField(
                                text: $inputText,
                                placeholder: "insert_new_name",
                                maxLength: 30,
                                isFocused: $textFieldFocused
                            )
                            .frame(width: 190)
                            .help("renaming_help")

                            Button("confirm") {
                                confirmRenameDevice()
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        if selectedDeviceToRename == nil && !CSM.Renamed.devices.isEmpty {
                            Button("undo_all") {
                                undoAllRenamedDevices()
                            }
                        }

                        Spacer()
                    }
                }
            }
        }
        .padding(10)
        .frame(minWidth: WindowWidth.value, minHeight: 600)
        .appBackground(reduceTransparency)
    }
}
