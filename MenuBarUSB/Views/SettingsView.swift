//
//  AboutView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import SwiftUI
import ServiceManagement
import AppKit

struct SettingsView: View {
    @EnvironmentObject var manager: USBDeviceManager
    
    @Binding var currentWindow: AppWindow
    
    @State private var showMessage: Bool = false
    @State private var showRenameDevices: Bool = false
    @State private var showCamouflagedDevices: Bool = false
    
    @State private var selectedDeviceToCamouflage: USBDevice?;
    @State private var selectedDeviceToRename: USBDevice?;
    @State private var inputText: String = "";
    @State private var textFieldFocused: Bool = false
    @State private var activeRowID: UUID? = nil
    
    @State private var tryingToResetSettings = false;
    @State private var checkingUpdate = false
    @State private var updateAvailable = false
    @State private var latestVersion: String = ""
    @State private var releaseURL: URL? = nil
    
    @State private var showSystemOptions = false;
    @State private var showIconOptions = false;
    @State private var showInterfaceOptions = false;
    @State private var showInfoOptions = false;
    @State private var showHeritageOptions = false;
    @State private var showOthersOptions = false;
    
    @State private var invisibleIconOptions = false;
    @State private var invisibleInterfaceOptions = false;
    @State private var invisibleInfoOptions = false;
    @State private var invisibleHeritageOptions = false;
    @State private var invisibleOthersOptions = false;
    
    @AppStorage(StorageKeys.launchAtLogin) private var launchAtLogin = false
    @AppStorage(StorageKeys.convertHexa) private var convertHexa = false
    @AppStorage(StorageKeys.longList) private var longList = false
    @AppStorage(StorageKeys.hideTechInfo) private var hideTechInfo = false
    @AppStorage(StorageKeys.showPortMax) private var showPortMax = false
    @AppStorage(StorageKeys.renamedIndicator) private var renamedIndicator = false
    @AppStorage(StorageKeys.camouflagedIndicator) private var camouflagedIndicator = false
    @AppStorage(StorageKeys.showNotifications) private var showNotifications = false
    @AppStorage(StorageKeys.reduceTransparency) private var reduceTransparency = false
    @AppStorage(StorageKeys.disableNotifCooldown) private var disableNotifCooldown = false
    @AppStorage(StorageKeys.disableInheritanceLayout) private var disableInheritanceLayout = false
    @AppStorage(StorageKeys.forceDarkMode) private var forceDarkMode = false
    @AppStorage(StorageKeys.forceLightMode) private var forceLightMode = false
    @AppStorage(StorageKeys.increasedIndentationGap) private var increasedIndentationGap = false
    @AppStorage(StorageKeys.hideSecondaryInfo) private var hideSecondaryInfo = false
    @AppStorage(StorageKeys.hideUpdate) private var hideUpdate = false
    @AppStorage(StorageKeys.hideDonate) private var hideDonate = false
    @AppStorage(StorageKeys.noTextButtons) private var noTextButtons = false
    @AppStorage(StorageKeys.hideCount) private var hideCount = false
    @AppStorage(StorageKeys.numberRepresentation) private var numberRepresentation: NumberRepresentation = .base10
    @AppStorage(StorageKeys.macBarIcon) private var macBarIcon: String = "cable.connector"
    @AppStorage(StorageKeys.hideMenubarIcon) private var hideMenubarIcon = false
    @AppStorage(StorageKeys.restartButton) private var restartButton = false
    @AppStorage(StorageKeys.mouseHoverInfo) private var mouseHoverInfo = false
    @AppStorage(StorageKeys.profilerButton) private var profilerButton = false
    @AppStorage(StorageKeys.disableContextMenuSearch) private var disableContextMenuSearch = false
    
    @CodableAppStorage(StorageKeys.renamedDevices) private var renamedDevices: [RenamedDevice] = []
    @CodableAppStorage(StorageKeys.camouflagedDevices) private var camouflagedDevices: [CamouflagedDevice] = []
    @CodableAppStorage(StorageKeys.inheritedDevices) private var inheritedDevices: [HeritageDevice] = []
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }
    
    func categoryButton(toggle: Binding<Bool>, label: LocalizedStringKey) -> some View {
        
        let anyBottomOptionInUse: Bool = showRenameDevices || showCamouflagedDevices
        
        return HStack {
            Image(systemName: toggle.wrappedValue ? "chevron.down" : "chevron.up")
            Text(label)
                .font(.system(size: 13.5))
                .fontWeight(.light)
        }
        .onTapGesture {
            manageShowOptions(binding: toggle)
        }
        .opacity(anyBottomOptionInUse ? 0.4 : 1.0)
        .disabled(anyBottomOptionInUse)
    }
    
    func resetAppData() {
        let fileManager = FileManager.default
        
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
        }
        
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
           let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first,
           let bundleID = Bundle.main.bundleIdentifier {
            
            let appSupportPath = appSupport.appendingPathComponent(bundleID).path
            let cachesPath = caches.appendingPathComponent(bundleID).path
            
            try? fileManager.removeItem(atPath: appSupportPath)
            try? fileManager.removeItem(atPath: cachesPath)
        }
    }
    
    func getIcons() -> [String] {
        var icons: [String] = [
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
        ]
        if #available(macOS 15.0, *) {
            icons.append(contentsOf: [
                "powerplug.portrait",
                "powerplug.portrait.fill",
                "powercord",
                "powercord.fill",
                "cat.fill",
                "dog.fill",
            ])
        }
        if #available(macOS 26.0, *) {
            icons.append(contentsOf: [
                "inset.filled.topthird.middlethird.bottomthird.rectangle",
            ])
        }
        return icons
    }
    
    func untoggleShowOptions() {
        showSystemOptions = false
        showInterfaceOptions = false
        showInfoOptions = false
        showHeritageOptions = false
        showOthersOptions = false
        showIconOptions = false
    }
    
    func manageShowOptions(binding: Binding<Bool>) {
        if binding.wrappedValue {
            binding.wrappedValue.toggle()
        } else {
            untoggleShowOptions()
            binding.wrappedValue = true
        }
    }
    
    public func toggleLoginItem(enabled: Bool) {
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
    
    var body: some View {
        
        let anyBottomOptionInUse: Bool = showRenameDevices || showCamouflagedDevices
            
        VStack(alignment: .leading, spacing: 20) {
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MenuBarUSB")
                        .font(.title2)
                        .bold()
                    Text(String(format: NSLocalizedString("version", comment: "APP VERSION"), appVersion))
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
                        
                        Link("\(String(localized: "open_download_page")) (v\(latestVersion))", destination: releaseURL)
                            .buttonStyle(.borderedProminent)
                    }
                }
                
                if !updateAvailable {
                    
                    HStack {
                        if (!hideUpdate) {
                            Button {
                                checkForUpdate()
                            } label: {
                                if checkingUpdate {
                                    ProgressView()
                                } else {
                                    Label(!latestVersion.isEmpty ? "updated" : "check_for_updates", systemImage: "checkmark.circle")
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if (!hideDonate) {
                            Button {
                                currentWindow = .donate
                            } label: {
                                Label("donate", systemImage: "hand.thumbsup.circle")
                            }
                            .disabled(anyBottomOptionInUse)
                        }
                    }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                
                categoryButton(toggle: $showSystemOptions, label: "systemCategory")
                
                if (showSystemOptions) {
                    ToggleRow(
                        label: String(localized: "open_on_startup"),
                        description: String(localized: "open_on_startup_description"),
                        binding: $launchAtLogin,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: { value in
                            toggleLoginItem(enabled: value)
                        },
                    )
                    ToggleRow(
                        label: String(localized: "reduce_transparency"),
                        description: String(localized: "reduce_transparency_description"),
                        binding: $reduceTransparency,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        disabled: forceDarkMode || forceLightMode,
                        onToggle: {_ in},
                    )
                    ToggleRow(
                        label: String(localized: "force_dark_mode"),
                        description: String(localized: "force_dark_mode_description"),
                        binding: $forceDarkMode,
                        activeRowID: $activeRowID,
                        incompatibilities: [forceLightMode],
                        onToggle: { value in
                            if (value == true) {
                                forceLightMode = false
                            }
                            
                        },
                    )
                    ToggleRow(
                        label: String(localized: "force_light_mode"),
                        description: String(localized: "force_light_mode_description"),
                        binding: $forceLightMode,
                        activeRowID: $activeRowID,
                        incompatibilities: [forceDarkMode],
                        onToggle: { value in
                            if (value == true) {
                                forceDarkMode = false
                            }
                        },
                    )
                    ToggleRow(
                        label: String(localized: "show_notification"),
                        description: String(localized: "show_notification_description"),
                        binding: $showNotifications,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: { value in
                            if (value == false) {
                                disableNotifCooldown = false
                            }
                        },
                    )
                    ToggleRow(
                        label: String(localized: "disable_notification_cooldown"),
                        description: String(localized: "disable_notification_cooldown_description"),
                        binding: $disableNotifCooldown,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        disabled: showNotifications == false,
                        onToggle: {_ in},
                    )
                }
                
                categoryButton(toggle: $showIconOptions, label: "icon_category")
                
                if (showIconOptions) {
                    VStack(alignment: .leading, spacing: 16) {
                        ToggleRow(
                            label: String(localized: "hide_menubar_icon"),
                            description: String(localized: "hide_menubar_icon_description"),
                            binding: $hideMenubarIcon,
                            activeRowID: $activeRowID,
                            incompatibilities: nil,
                            disabled: hideCount,
                            onToggle: { _ in hideCount = false },
                        )
                        ToggleRow(
                            label: String(localized: "hide_count"),
                            description: String(localized: "hide_count_description"),
                            binding: $hideCount,
                            activeRowID: $activeRowID,
                            incompatibilities: nil,
                            disabled: hideMenubarIcon,
                            onToggle: { _ in hideMenubarIcon = false },
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
                        
                        HStack{
                            Menu {
                                ForEach(getIcons(), id: \.self) { item in
                                    Button {
                                        macBarIcon = item
                                    } label: {
                                        HStack {
                                            Image(systemName: item)
                                            if !hideCount {
                                                Text(NumberConverter(manager.devices.count).convert())
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Label("icon", systemImage: macBarIcon)
                                    .background(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))
                            }
                            .disabled(hideMenubarIcon)
                            
                            Menu(LocalizedStringKey(numberRepresentation.rawValue)) {
                                let nr: [NumberRepresentation] = [.base10, .egyptian, .greek, .roman]
                                ForEach(nr, id: \.self) { item in
                                    Button {
                                        numberRepresentation = item
                                        Utils.killApp()
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
                
                categoryButton(toggle: $showInterfaceOptions, label: "uiCategory")
                
                if (showInterfaceOptions) {
                    ToggleRow(
                        label: String(localized: "hide_technical_info"),
                        description: String(localized: "hide_technical_info_description"),
                        binding: $hideTechInfo,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: { value in
                            if (value == false) {
                                mouseHoverInfo = false
                            }
                        },
                    )
                    ToggleRow(
                        label: String(localized: "mouse_hover_info"),
                        description: String(localized: "mouse_hover_info_description"),
                        binding: $mouseHoverInfo,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        disabled: !hideTechInfo,
                        onToggle: { _ in},
                    )
                    ToggleRow(
                        label: String(localized: "hide_secondary_info"),
                        description: String(localized: "hide_secondary_info_description"),
                        binding: $hideSecondaryInfo,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: { _ in },
                    )
                    ToggleRow(
                        label: String(localized: "long_list"),
                        description: String(localized: "long_list_description"),
                        binding: $longList,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: {_ in},
                    )
                    ToggleRow(
                        label: String(localized: "hidden_indicator"),
                        description: String(localized: "hidden_indicator_description"),
                        binding: $camouflagedIndicator,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: {_ in },
                    )
                    ToggleRow(
                        label: String(localized: "renamed_indicator"),
                        description: String(localized: "renamed_indicator_description"),
                        binding: $renamedIndicator,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: {_ in},
                    )
                    ToggleRow(
                        label: String(localized: "disable_context_menu_search"),
                        description: String(localized: "disable_context_menu_search_description"),
                        binding: $disableContextMenuSearch,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: {_ in},
                    )
                }
                
                categoryButton(toggle: $showInfoOptions, label: "usbCategory")
                
                if (showInfoOptions) {
                    
                    Button {
                        showRenameDevices.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "pencil.and.scribble")
                            Text("rename_device")
                        }
                    }
                    .disabled(anyBottomOptionInUse)
                    
                    Button {
                        showCamouflagedDevices.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "eye")
                            Text("hide_device")
                        }
                    }
                    .disabled(anyBottomOptionInUse)
                    
                    ToggleRow(
                        label: String(localized: "show_port_max"),
                        description: String(localized: "show_port_max_description"),
                        binding: $showPortMax,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        disabled: hideTechInfo && !mouseHoverInfo,
                        onToggle: {_ in},
                    )
                    ToggleRow(
                        label: String(localized: "convert_hexa"),
                        description: String(localized: "convert_hexa_description"),
                        binding: $convertHexa,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        disabled: hideTechInfo && !mouseHoverInfo,
                        onToggle: {_ in},
                    )
                }
                
                categoryButton(toggle: $showHeritageOptions, label: "heritageCategory")
                
                if (showHeritageOptions) {
                    
                    Button {
                        currentWindow = .heritage
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("create_inheritance")
                        }
                    }
                    .disabled(anyBottomOptionInUse)
                    
                    Button {
                        currentWindow = .inheritanceTree
                    } label: {
                        HStack {
                            Image(systemName: "tree")
                            Text("view_inheritance_tree")
                        }
                    }
                    .disabled(anyBottomOptionInUse)
                    
                    ToggleRow(
                        label: String(localized: "disable_inheritance_layout"),
                        description: String(localized: "disable_inheritance_layout_description"),
                        binding: $disableInheritanceLayout,
                        activeRowID: $activeRowID,
                        incompatibilities: [increasedIndentationGap],
                        onToggle: {_ in increasedIndentationGap = false},
                    )
                    ToggleRow(
                        label: String(localized: "increased_indentation_gap"),
                        description: String(localized: "increased_indentation_gap_description"),
                        binding: $increasedIndentationGap,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        disabled: disableInheritanceLayout,
                        onToggle: {_ in},
                    )
                }
                
                categoryButton(toggle: $showOthersOptions, label: "othersCategory")
                
                if (showOthersOptions) {
                    
                    ToggleRow(
                        label: String(localized: "hide_check_update"),
                        description: String(localized: "hide_check_update_description"),
                        binding: $hideUpdate,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: {_ in},
                    )
                    ToggleRow(
                        label: String(localized: "hide_donate"),
                        description: String(localized: "hide_donate_description"),
                        binding: $hideDonate,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: {_ in},
                    )
                    ToggleRow(
                        label: String(localized: "no_text_buttons"),
                        description: String(localized: "no_text_buttons_description"),
                        binding: $noTextButtons,
                        activeRowID: $activeRowID,
                        incompatibilities: nil,
                        onToggle: {_ in},
                    )
                    ToggleRow(
                        label: String(localized: "restart_button"),
                        description: String(localized: "restart_button_description"),
                        binding: $restartButton,
                        activeRowID: $activeRowID,
                        incompatibilities: [profilerButton],
                        onToggle: { value in
                            if (value == true) {
                                profilerButton = false;
                            }
                        },
                    )
                    if #available(macOS 15.0, *) {
                        ToggleRow(
                            label: String(localized: "profiler_shortcut"),
                            description: String(localized: "profiler_shortcut_description"),
                            binding: $profilerButton,
                            activeRowID: $activeRowID,
                            incompatibilities: [restartButton],
                            onToggle: { value in
                                if (value == true) {
                                    restartButton = false;
                                }
                            },
                        )
                    }
                    
                    if #available(macOS 15.0, *) {
                        Button {
                            Utils.openSysInfo()
                        } label: {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                Text("open_profiler")
                            }
                        }
                        .disabled(tryingToResetSettings)
                    }
                    
                    Button {
                        tryingToResetSettings = true;
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill.badge.gearshape")
                            Text("restore_default_settings")
                        }
                    }
                    .disabled(tryingToResetSettings)
                    
                    if (tryingToResetSettings) {
                        HStack(spacing: 12) {
                            Text("are_you_sure")
                            Button("no") {
                                tryingToResetSettings = false;
                            }
                            Button("yes_confirm") {
                                resetAppData()
                                tryingToResetSettings = false;
                                showOthersOptions = false;
                                if let sound = NSSound(named: NSSound.Name("Bottle")) {
                                    sound.play()
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                    Utils.killApp()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    
                }
                
                
                
            }
            
            Spacer()
            
            VStack(alignment: .leading) {
                
                if (anyBottomOptionInUse) {
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
                    
                    if (!anyBottomOptionInUse) {
                        Button(action: {currentWindow = .devices}) {
                            Label("back", systemImage: "arrow.uturn.backward")
                        }
                    }
                    
                }
                
                if (anyBottomOptionInUse) {
                    Divider()
                }
                
                if showCamouflagedDevices {
                    HStack(spacing: 12) {
                        Menu {
                            ForEach(manager.devices) { device in
                                let renamedDevice = renamedDevices.first { $0.deviceId == USBDevice.uniqueId(device) }
                                let buttonLabel = renamedDevice?.name ?? device.name
                                Button(buttonLabel) {
                                    selectedDeviceToCamouflage = device
                                }
                            }
                        } label: {
                            Text(selectedDeviceToCamouflage?.name ?? String(localized: "device"))
                        }
                        
                        if selectedDeviceToCamouflage != nil {
                            
                            if (inheritedDevices.contains { $0.inheritsFrom == USBDevice.uniqueId(selectedDeviceToCamouflage!) }) {
                                Text("cant_hide_heir")
                                    .font(.subheadline)
                            } else {
                                Button("confirm") {
                                    let uniqueId = USBDevice.uniqueId(selectedDeviceToCamouflage!)
                                    let newDevice = CamouflagedDevice(deviceId: uniqueId)
                                    camouflagedDevices.removeAll { $0.deviceId == uniqueId }
                                    camouflagedDevices.append(newDevice)
                                    selectedDeviceToCamouflage = nil
                                    showCamouflagedDevices = false
                                    manager.refresh()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        
                        if selectedDeviceToCamouflage == nil && !camouflagedDevices.isEmpty {
                            Button("undo_all") {
                                camouflagedDevices.removeAll()
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
                            ForEach(manager.devices) { device in
                                let renamedDevice = renamedDevices.first { $0.deviceId == USBDevice.uniqueId(device) }
                                let buttonLabel = renamedDevice?.name ?? device.name
                                Button(buttonLabel) {
                                    inputText = ""
                                    selectedDeviceToRename = device
                                }
                            }
                        } label: {
                            Text(selectedDeviceToRename?.name ?? String(localized: "device"))
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
                                let uniqueId = USBDevice.uniqueId(selectedDeviceToRename!)
                                if inputText.isEmpty {
                                    renamedDevices.removeAll { $0.deviceId == uniqueId }
                                } else {
                                    renamedDevices.removeAll { $0.deviceId == uniqueId }
                                    renamedDevices.append(RenamedDevice(deviceId: uniqueId, name: inputText))
                                }
                                inputText = ""
                                selectedDeviceToRename = nil
                                showRenameDevices = false
                                manager.refresh()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        
                        if selectedDeviceToRename == nil && !renamedDevices.isEmpty {
                            Button(String(localized: "undo_all")) {
                                renamedDevices.removeAll()
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
    
    private func checkForUpdate() {
        checkingUpdate = true
        updateAvailable = false
        latestVersion = ""
        releaseURL = nil
        
        guard let url = URL(string: "https://api.github.com/repos/rafaelSwi/MenuBarUSB/releases/latest") else {
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
                    updateAvailable = isVersion(appVersion, olderThan: latest)
                    if let sound = NSSound(named: NSSound.Name(updateAvailable ? "Submarine" : "Glass")) {
                        sound.play()
                    }
                }
            }
        }.resume()
    }
    
    private func isVersion(_ v1: String, olderThan v2: String) -> Bool {
        let v1Components = v1.split(separator: ".").compactMap { Int($0) }
        let v2Components = v2.split(separator: ".").compactMap { Int($0) }
        for (a, b) in zip(v1Components, v2Components) {
            if a < b { return true }
            if a > b { return false }
        }
        return v1Components.count < v2Components.count
    }
}
