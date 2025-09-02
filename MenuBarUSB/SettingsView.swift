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
    @State private var showRenamedIndicatorDescription: Bool = false;
    @State private var showCamouflagedIndicatorDescription: Bool = false;
    
    @AppStorage(StorageKeys.launchAtLogin) private var launchAtLogin = false
    @AppStorage(StorageKeys.convertHexa) private var convertHexa = false
    @AppStorage(StorageKeys.longList) private var longList = false
    @AppStorage(StorageKeys.showPortMax) private var showPortMax = false
    @AppStorage(StorageKeys.renamedIndicator) private var renamedIndicator = false
    @AppStorage(StorageKeys.camouflagedIndicator) private var camouflagedIndicator = false
    
    @CodableAppStorage(StorageKeys.renamedDevices) private var renamedDevices: [RenamedDevice] = []
    @CodableAppStorage(StorageKeys.camouflagedDevices) private var camouflagedDevices: [CamouflagedDevice] = []
    
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
                            Text(String(localized: "check_for_updates"))
                        }
                    }
                    .buttonStyle(.bordered)
                }
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
                        showShowPortMaxDescription = false;
                        showConvertHexaDescription = false;
                        showRenamedIndicatorDescription = false;
                        showCamouflagedIndicatorDescription = false;
                    }
                )
                ToggleRow(
                    label: String(localized: "show_port_max"),
                    description: String(localized: "show_port_max_description"),
                    binding: $showPortMax,
                    showMessage: $showShowPortMaxDescription,
                    untoggle: {
                        showLongListDescription = false;
                        showConvertHexaDescription = false;
                        showRenamedIndicatorDescription = false;
                        showCamouflagedIndicatorDescription = false;
                    }
                )
                ToggleRow(
                    label: String(localized: "convert_hexa"),
                    description: String(localized: "convert_hexa_description"),
                    binding: $convertHexa,
                    showMessage: $showConvertHexaDescription,
                    untoggle: {
                        showLongListDescription = false;
                        showShowPortMaxDescription = false;
                        showRenamedIndicatorDescription = false;
                        showCamouflagedIndicatorDescription = false;
                    }
                )
                ToggleRow(
                    label: String(localized: "hidden_indicator"),
                    description: String(localized: "hidden_indicator_description"),
                    binding: $camouflagedIndicator,
                    showMessage: $showCamouflagedIndicatorDescription,
                    untoggle: {
                        showLongListDescription = false;
                        showConvertHexaDescription = false;
                        showShowPortMaxDescription = false;
                        showRenamedIndicatorDescription = false;
                    }
                )
                ToggleRow(
                    label: String(localized: "renamed_indicator"),
                    description: String(localized: "renamed_indicator_description"),
                    binding: $renamedIndicator,
                    showMessage: $showRenamedIndicatorDescription,
                    untoggle: {
                        showLongListDescription = false;
                        showConvertHexaDescription = false;
                        showShowPortMaxDescription = false;
                        showCamouflagedIndicatorDescription = false;
                    }
                )
            }
            
            Spacer()
            
            HStack {
                Button(String(localized: "hide_device")) {
                    showRenameDevices = false;
                    selectedDeviceToRename = nil;
                    inputText = "";
                    if (showCamouflagedDevices) {
                        showCamouflagedDevices = false;
                        selectedDeviceToCamouflage = nil;
                    } else {
                        showCamouflagedDevices = true;
                    }
                }
                
                if (showCamouflagedDevices) {
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
                }
                
                if (showCamouflagedDevices && selectedDeviceToCamouflage == nil && camouflagedDevices.count > 0) {
                    Button {
                        camouflagedDevices.removeAll();
                        showCamouflagedDevices = false;
                    } label: {
                        Text(String(localized: "undo_all"))
                    }
                }
                
                if (selectedDeviceToCamouflage != nil) {
                    Button {
                        let uniqueId = USBDevice.uniqueId(selectedDeviceToCamouflage!)
                        let newDevice = CamouflagedDevice(deviceId: uniqueId)
                        camouflagedDevices.removeAll { $0.deviceId == uniqueId }
                        camouflagedDevices.append(newDevice)
                        selectedDeviceToCamouflage = nil;
                        showCamouflagedDevices = false;
                    } label: {
                        Text(String(localized: "confirm"))
                            .frame(width: 100)
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Spacer()
                
            }
            
            HStack {
                Button(String(localized: "rename_device")) {
                    showCamouflagedDevices = false;
                    selectedDeviceToCamouflage = nil;
                    if (showRenameDevices) {
                        showRenameDevices = false;
                        selectedDeviceToRename = nil;
                        inputText = "";
                    } else {
                        showRenameDevices = true;
                    }
                }
                
                if (showRenameDevices) {
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
                }
                
                if (showRenameDevices && selectedDeviceToRename == nil && renamedDevices.count > 0) {
                    Button {
                        renamedDevices.removeAll();
                        showRenameDevices = false;
                    } label: {
                        Text(String(localized: "undo_all"))
                    }
                }
                
                if (selectedDeviceToRename != nil) {
                    HStack {
                        TextFieldWithLimit(
                            text: $inputText,
                            placeholder: String(localized: "insert_new_name"),
                            maxLength: 30
                        )
                        .frame(width: 190)
                        .help(String(localized: "renaming_help"))
                        
                        Button {
                            let uniqueId = USBDevice.uniqueId(selectedDeviceToRename!)
                            let newDevice = RenamedDevice(deviceId: uniqueId, name: inputText)
                            if (inputText == "") {
                                renamedDevices.removeAll { $0.deviceId == uniqueId }
                            } else {
                                renamedDevices.removeAll { $0.deviceId == uniqueId }
                                renamedDevices.append(newDevice)
                            }
                            inputText = "";
                            selectedDeviceToRename = nil;
                            showRenameDevices = false;
                        } label: {
                            Text(String(localized: "confirm"))
                                .frame(width: 100)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                
                Spacer()
                Button(String(localized: "close_about_window")) {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(minWidth: 400, minHeight: 400)
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .shadow(radius: 10)
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
