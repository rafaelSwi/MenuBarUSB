//
//  AboutView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openWindow) var openWindow
    @EnvironmentObject var manager: USBDeviceManager
    
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
    
    @State private var showOpenOnStartupDescription: Bool = false;
    @State private var showConvertHexaDescription: Bool = false;
    @State private var showLongListDescription: Bool = false;
    @State private var showShowPortMaxDescription: Bool = false;
    @State private var showHideTechInfoDescription: Bool = false
    @State private var showRenamedIndicatorDescription: Bool = false;
    @State private var showCamouflagedIndicatorDescription: Bool = false;
    
    @AppStorage(StorageKeys.launchAtLogin) private var launchAtLogin = false
    @AppStorage(StorageKeys.convertHexa) private var convertHexa = false
    @AppStorage(StorageKeys.longList) private var longList = false
    @AppStorage(StorageKeys.hideTechInfo) private var hideTechInfo = false
    @AppStorage(StorageKeys.showPortMax) private var showPortMax = false
    @AppStorage(StorageKeys.renamedIndicator) private var renamedIndicator = false
    @AppStorage(StorageKeys.camouflagedIndicator) private var camouflagedIndicator = false
    
    @CodableAppStorage(StorageKeys.renamedDevices) private var renamedDevices: [RenamedDevice] = []
    @CodableAppStorage(StorageKeys.camouflagedDevices) private var camouflagedDevices: [CamouflagedDevice] = []
    
    func untoggleAllDesc() {
        showShowPortMaxDescription = false;
        showLongListDescription = false;
        showConvertHexaDescription = false;
        showRenamedIndicatorDescription = false;
        showCamouflagedIndicatorDescription = false;
        showHideTechInfoDescription = false;
    }
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
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
                        Link("\(String(localized: "open_download_page")) (v\(latestVersion))", destination: releaseURL)
                            .buttonStyle(.borderedProminent)
                    }
                } else if !checkingUpdate && !latestVersion.isEmpty {
                    Text(String(localized: "up_to_date"))
                        .foregroundColor(.green)
                }
                
                if !updateAvailable {
                    Button {
                        checkForUpdate()
                    } label: {
                        if checkingUpdate {
                            ProgressView()
                        } else {
                            Label(String(localized: "check_for_updates"), systemImage: "checkmark.circle")
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Button {
                    openWindow(id: "donate")
                } label: {
                    Label(String(localized: "donate"), systemImage: "hand.thumbsup.circle")
                }
                .font(.system(size: 12)) // TODO: DELETE
            }
            
            Divider()
            
            Toggle(String(localized: "open_on_startup"), isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { enabled in
                    toggleLoginItem(enabled: enabled)
                }
            
            VStack(spacing: 12) {
                ToggleRow(
                    label: String(localized: "long_list"),
                    description: String(localized: "long_list_description"),
                    binding: $longList,
                    showMessage: $showLongListDescription,
                    untoggle: {
                        untoggleAllDesc();
                    }
                )
                ToggleRow(
                    label: String(localized: "hide_technical_info"),
                    description: String(localized: "hide_technical_info_description"),
                    binding: $hideTechInfo,
                    showMessage: $showHideTechInfoDescription,
                    untoggle: {
                        untoggleAllDesc();
                    }
                )
                ToggleRow(
                    label: String(localized: "show_port_max"),
                    description: String(localized: "show_port_max_description"),
                    binding: $showPortMax,
                    showMessage: $showShowPortMaxDescription,
                    untoggle: {
                        untoggleAllDesc();
                    }
                )
                ToggleRow(
                    label: String(localized: "convert_hexa"),
                    description: String(localized: "convert_hexa_description"),
                    binding: $convertHexa,
                    showMessage: $showConvertHexaDescription,
                    untoggle: {
                        untoggleAllDesc();
                    }
                )
                ToggleRow(
                    label: String(localized: "hidden_indicator"),
                    description: String(localized: "hidden_indicator_description"),
                    binding: $camouflagedIndicator,
                    showMessage: $showCamouflagedIndicatorDescription,
                    untoggle: {
                        untoggleAllDesc();
                    }
                )
                ToggleRow(
                    label: String(localized: "renamed_indicator"),
                    description: String(localized: "renamed_indicator_description"),
                    binding: $renamedIndicator,
                    showMessage: $showRenamedIndicatorDescription,
                    untoggle: {
                        untoggleAllDesc();
                    }
                )
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    if (!showCamouflagedDevices) {
                        Button(showRenameDevices ? String(localized: "cancel") : String(localized: "rename_device")) {
                            showRenameDevices.toggle()
                            showCamouflagedDevices = false
                            selectedDeviceToCamouflage = nil
                            selectedDeviceToRename = nil
                            inputText = ""
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if (!showRenameDevices) {
                        Button(showCamouflagedDevices ? String(localized: "cancel") : String(localized: "hide_device")) {
                            showCamouflagedDevices.toggle()
                            showRenameDevices = false
                            selectedDeviceToRename = nil
                            selectedDeviceToCamouflage = nil
                            inputText = ""
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()

                    Button(String(localized: "close_about_window")) {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }

                if (showRenameDevices || showCamouflagedDevices) {
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
                        .frame(width: 190)

                        if selectedDeviceToCamouflage != nil {
                            Button(String(localized: "confirm")) {
                                let uniqueId = USBDevice.uniqueId(selectedDeviceToCamouflage!)
                                let newDevice = CamouflagedDevice(deviceId: uniqueId)
                                camouflagedDevices.removeAll { $0.deviceId == uniqueId }
                                camouflagedDevices.append(newDevice)
                                selectedDeviceToCamouflage = nil
                                showCamouflagedDevices = false
                            }

                            .buttonStyle(.borderedProminent)
                        }

                        if selectedDeviceToCamouflage == nil && !camouflagedDevices.isEmpty {
                            Button(String(localized: "undo_all")) {
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
                        .frame(width: 190)

                        if selectedDeviceToRename != nil {
                            TextFieldWithLimit(
                                text: $inputText,
                                placeholder: String(localized: "insert_new_name"),
                                maxLength: 30
                            )
                            .frame(width: 190)
                            .help(String(localized: "renaming_help"))

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
        .padding(20)
        .frame(minWidth: 400, minHeight: 400)
        .background(.ultraThinMaterial)
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
