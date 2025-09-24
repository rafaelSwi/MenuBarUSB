//
//  AboutView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var manager: USBDeviceManager
    
    @Binding var currentWindow: AppWindow
    
    @State private var showMessage: Bool = false
    @State private var showRenameDevices: Bool = false
    @State private var showCamouflagedDevices: Bool = false
    
    @State private var selectedDeviceToCamouflage: USBDevice?;
    @State private var selectedDeviceToRename: USBDevice?;
    @State private var inputText: String = "";
    
    @State private var checkingUpdate = false
    @State private var updateAvailable = false
    @State private var latestVersion: String = ""
    @State private var releaseURL: URL? = nil
    
    @State private var showSystemOptions = false;
    @State private var showInterfaceOptions = false;
    @State private var showInfoOptions = false;
    @State private var showHeritageOptions = false;
    @State private var showOthersOptions = false;
    
    @State private var showLaunchAtLoginDescription: Bool = false;
    @State private var showConvertHexaDescription: Bool = false;
    @State private var showLongListDescription: Bool = false;
    @State private var showShowNotificationsDescription: Bool = false;
    @State private var showShowPortMaxDescription: Bool = false;
    @State private var showHideTechInfoDescription: Bool = false
    @State private var showRenamedIndicatorDescription: Bool = false;
    @State private var showCamouflagedIndicatorDescription: Bool = false;
    @State private var showReduceTransparencyDescription: Bool = false;
    @State private var showDisableNotifCooldownDescription: Bool = false;
    @State private var showDisableInheritanceLayoutDescription: Bool = false;
    @State private var showForceDarkModeDescription: Bool = false;
    @State private var showForceLightModeDescription: Bool = false;
    @State private var showIncreasedIndentationGapDescription: Bool = false;
    @State private var showHideSecondaryInfoDescription: Bool = false;
    @State private var showHideUpdateDescription: Bool = false;
    @State private var showHideDonateDescription: Bool = false;
    @State private var showNoTextButtonsDescription: Bool = false;
    
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
    
    @CodableAppStorage(StorageKeys.renamedDevices) private var renamedDevices: [RenamedDevice] = []
    @CodableAppStorage(StorageKeys.camouflagedDevices) private var camouflagedDevices: [CamouflagedDevice] = []
    @CodableAppStorage(StorageKeys.inheritedDevices) private var inheritedDevices: [HeritageDevice] = []
    
    func untoggleAllDesc() {
        showShowPortMaxDescription = false;
        showLongListDescription = false;
        showConvertHexaDescription = false;
        showRenamedIndicatorDescription = false;
        showCamouflagedIndicatorDescription = false;
        showHideTechInfoDescription = false;
        showShowNotificationsDescription = false;
        showReduceTransparencyDescription = false;
        showDisableNotifCooldownDescription = false;
        showLaunchAtLoginDescription = false;
        showDisableInheritanceLayoutDescription = false;
        showForceDarkModeDescription = false;
        showForceLightModeDescription = false;
        showIncreasedIndentationGapDescription = false;
        showHideSecondaryInfoDescription = false;
        showHideUpdateDescription = false;
        showHideDonateDescription = false;
        showNoTextButtonsDescription = false;
    }
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }
    
    func untoggleShowOptions() {
        showSystemOptions = false
        showInterfaceOptions = false
        showInfoOptions = false
        showHeritageOptions = false
        showOthersOptions = false
    }
    
    func manageShowOptions(exception: inout Bool) {
        if (exception) {
            exception = !exception
        } else {
            untoggleShowOptions()
            exception = true
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
                        }
                    }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                
                HStack {
                    Image(systemName: showSystemOptions ? "chevron.down" : "chevron.up")
                    Text(String(localized: "systemCategory"))
                        .font(.system(size: 13.5))
                        .fontWeight(.light)
                }
                .onTapGesture {
                    manageShowOptions(exception: &showSystemOptions)
                }
                
                if (showSystemOptions) {
                    ToggleRow(
                        label: String(localized: "open_on_startup"),
                        description: String(localized: "open_on_startup_description"),
                        binding: $launchAtLogin,
                        showMessage: $showLaunchAtLoginDescription,
                        incompatibilities: nil,
                        onToggle: { value in
                            toggleLoginItem(enabled: value)
                        },
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "show_notification"),
                        description: String(localized: "show_notification_description"),
                        binding: $showNotifications,
                        showMessage: $showShowNotificationsDescription,
                        incompatibilities: nil,
                        onToggle: { value in
                            if (value == false) {
                                disableNotifCooldown = false
                            }
                        },
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "disable_notification_cooldown"),
                        description: String(localized: "disable_notification_cooldown_description"),
                        binding: $disableNotifCooldown,
                        showMessage: $showDisableNotifCooldownDescription,
                        incompatibilities: nil,
                        disabled: showNotifications == false,
                        onToggle: {_ in},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                }
                
                HStack {
                    Image(systemName: showInterfaceOptions ? "chevron.down" : "chevron.up")
                    Text(String(localized: "uiCategory"))
                        .font(.system(size: 13.5))
                        .fontWeight(.light)
                }
                .onTapGesture {
                    manageShowOptions(exception: &showInterfaceOptions)
                }
                
                if (showInterfaceOptions) {
                    ToggleRow(
                        label: String(localized: "hide_technical_info"),
                        description: String(localized: "hide_technical_info_description"),
                        binding: $hideTechInfo,
                        showMessage: $showHideTechInfoDescription,
                        incompatibilities: [showPortMax, convertHexa],
                        onToggle: { value in
                            if (value == true) {
                                showPortMax = false
                                convertHexa = false
                            }
                        },
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "hide_secondary_info"),
                        description: String(localized: "hide_secondary_info_description"),
                        binding: $hideSecondaryInfo,
                        showMessage: $showHideSecondaryInfoDescription,
                        incompatibilities: [showPortMax, convertHexa],
                        onToggle: { value in
                            if (value == true) {
                                showPortMax = false
                                convertHexa = false
                            }
                        },
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "long_list"),
                        description: String(localized: "long_list_description"),
                        binding: $longList,
                        showMessage: $showLongListDescription,
                        incompatibilities: nil,
                        onToggle: {_ in},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "reduce_transparency"),
                        description: String(localized: "reduce_transparency_description"),
                        binding: $reduceTransparency,
                        showMessage: $showReduceTransparencyDescription,
                        incompatibilities: nil,
                        onToggle: {_ in},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "force_dark_mode"),
                        description: String(localized: "force_dark_mode_description"),
                        binding: $forceDarkMode,
                        showMessage: $showForceDarkModeDescription,
                        incompatibilities: [forceLightMode],
                        disabled: forceLightMode,
                        onToggle: {_ in forceLightMode = false},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "force_light_mode"),
                        description: String(localized: "force_light_mode_description"),
                        binding: $forceLightMode,
                        showMessage: $showForceLightModeDescription,
                        incompatibilities: [forceDarkMode],
                        disabled: forceDarkMode,
                        onToggle: {_ in forceDarkMode = false},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "hidden_indicator"),
                        description: String(localized: "hidden_indicator_description"),
                        binding: $camouflagedIndicator,
                        showMessage: $showCamouflagedIndicatorDescription,
                        incompatibilities: nil,
                        onToggle: {_ in},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "renamed_indicator"),
                        description: String(localized: "renamed_indicator_description"),
                        binding: $renamedIndicator,
                        showMessage: $showRenamedIndicatorDescription,
                        incompatibilities: nil,
                        onToggle: {_ in},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                }
                
                HStack {
                    Image(systemName: showInfoOptions ? "chevron.down" : "chevron.up")
                    Text(String(localized: "usbCategory"))
                        .font(.system(size: 13.5))
                        .fontWeight(.light)
                }
                .onTapGesture {
                    manageShowOptions(exception: &showInfoOptions)
                }
                
                if (showInfoOptions) {
                    
                    Button {
                        showRenameDevices.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
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
                        showMessage: $showShowPortMaxDescription,
                        incompatibilities: nil,
                        disabled: hideTechInfo,
                        onToggle: {_ in},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "convert_hexa"),
                        description: String(localized: "convert_hexa_description"),
                        binding: $convertHexa,
                        showMessage: $showConvertHexaDescription,
                        incompatibilities: nil,
                        disabled: hideTechInfo,
                        onToggle: {_ in},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                }
                
                HStack {
                    Image(systemName: showHeritageOptions ? "chevron.down" : "chevron.up")
                    Text(String(localized: "heritageCategory"))
                        .font(.system(size: 13.5))
                        .fontWeight(.light)
                }
                .onTapGesture {
                    manageShowOptions(exception: &showHeritageOptions)
                }
                
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
                            Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                            Text("view_inheritance_tree")
                        }
                    }
                    .disabled(anyBottomOptionInUse)
                    
                    ToggleRow(
                        label: String(localized: "disable_inheritance_layout"),
                        description: String(localized: "disable_inheritance_layout_description"),
                        binding: $disableInheritanceLayout,
                        showMessage: $showDisableInheritanceLayoutDescription,
                        incompatibilities: [increasedIndentationGap],
                        onToggle: {_ in increasedIndentationGap = false},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "increased_indentation_gap"),
                        description: String(localized: "increased_indentation_gap_description"),
                        binding: $increasedIndentationGap,
                        showMessage: $showIncreasedIndentationGapDescription,
                        incompatibilities: nil,
                        disabled: disableInheritanceLayout,
                        onToggle: {_ in},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                }
                
                HStack {
                    Image(systemName: showOthersOptions ? "chevron.down" : "chevron.up")
                    Text(String(localized: "othersCategory"))
                        .font(.system(size: 13.5))
                        .fontWeight(.light)
                }
                .onTapGesture {
                    manageShowOptions(exception: &showOthersOptions)
                }
                
                if (showOthersOptions) {
                    
                    ToggleRow(
                        label: String(localized: "hide_check_update"),
                        description: String(localized: "hide_check_update_description"),
                        binding: $hideUpdate,
                        showMessage: $showHideUpdateDescription,
                        incompatibilities: nil,
                        onToggle: {_ in},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "hide_donate"),
                        description: String(localized: "hide_donate_description"),
                        binding: $hideDonate,
                        showMessage: $showHideDonateDescription,
                        incompatibilities: nil,
                        onToggle: {_ in},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "no_text_buttons"),
                        description: String(localized: "no_text_buttons_description"),
                        binding: $noTextButtons,
                        showMessage: $showNoTextButtonsDescription,
                        incompatibilities: nil,
                        onToggle: {_ in},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    
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
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        
                        if selectedDeviceToCamouflage == nil && !camouflagedDevices.isEmpty {
                            Button("undo_all") {
                                camouflagedDevices.removeAll()
                                showCamouflagedDevices = false
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
                            TextFieldWithLimit(
                                text: $inputText,
                                placeholder: String(localized: "insert_new_name"),
                                maxLength: 30
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
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        
                        if selectedDeviceToRename == nil && !renamedDevices.isEmpty {
                            Button(String(localized: "undo_all")) {
                                renamedDevices.removeAll()
                                showRenameDevices = false
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            
            
        }
        .padding(10)
        .frame(minWidth: 465, minHeight: 565)
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
