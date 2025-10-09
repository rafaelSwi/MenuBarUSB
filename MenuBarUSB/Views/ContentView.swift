//
//  ContentView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject var manager: USBDeviceManager
    @Environment(\.openURL) var openURL
    
    @State private var isHoveringDeviceId: String = ""
    @State private var isRenamingDeviceId: String = ""
    @State private var inputText: String = "";
    @State private var textFieldFocused: Bool = false
    @State private var devicesShowingMore: [USBDevice] = []
    
    @Binding var currentWindow: AppWindow
    
    @AppStorage(StorageKeys.convertHexa) private var convertHexa = false
    @AppStorage(StorageKeys.showPortMax) private var showPortMax = false
    @AppStorage(StorageKeys.longList) private var longList = false
    @AppStorage(StorageKeys.renamedIndicator) private var renamedIndicator = false
    @AppStorage(StorageKeys.camouflagedIndicator) private var camouflagedIndicator = false
    @AppStorage(StorageKeys.hideTechInfo) private var hideTechInfo = false
    @AppStorage(StorageKeys.disableInheritanceLayout) private var disableInheritanceLayout = false
    @AppStorage(StorageKeys.increasedIndentationGap) private var increasedIndentationGap = false
    @AppStorage(StorageKeys.hideSecondaryInfo) private var hideSecondaryInfo = false
    @AppStorage(StorageKeys.noTextButtons) private var noTextButtons = false
    @AppStorage(StorageKeys.restartButton) private var restartButton = false
    @AppStorage(StorageKeys.mouseHoverInfo) private var mouseHoverInfo = false
    @AppStorage(StorageKeys.profilerButton) private var profilerButton = false
    @AppStorage(StorageKeys.disableContextMenuSearch) private var disableContextMenuSearch = false
    @AppStorage(StorageKeys.showEthernet) private var showEthernet = false
    @AppStorage(StorageKeys.internetMonitoring) private var internetMonitoring = false
    @AppStorage(StorageKeys.trafficButton) private var trafficButton = false
    @AppStorage(StorageKeys.trafficButtonLabel) private var trafficButtonLabel = false
    @AppStorage(StorageKeys.searchEngine) private var searchEngine: SearchEngine = .google
    
    @CodableAppStorage(StorageKeys.renamedDevices) private var renamedDevices: [RenamedDevice] = []
    @CodableAppStorage(StorageKeys.camouflagedDevices) private var camouflagedDevices: [CamouflagedDevice] = []
    @CodableAppStorage(StorageKeys.inheritedDevices) private var inheritedDevices: [HeritageDevice] = []
    
    func windowHeight(longList: Bool, compactList: Bool) -> CGFloat? {
        if (manager.devices.isEmpty) {
            return nil
        }
        let baseValue: CGFloat = 200
        var multiplier: CGFloat = 25
        if longList {
            multiplier = 30
        }
        if compactList {
            multiplier = 12
        }
        let sum: CGFloat = baseValue + (CGFloat(manager.devices.count) * multiplier)
        var max: CGFloat = 380
        if longList {
            max += 315
        }
        return sum >= max ? max : sum
    }
    
    func sortedDevices() -> [USBDevice] {
        var sorted: [USBDevice] = []
        var visited: Set<String> = []
        
        var childrenMap: [String: [String]] = [:]
        for relation in inheritedDevices {
            childrenMap[relation.inheritsFrom, default: []].append(relation.deviceId)
        }
        
        func appendFamily(_ deviceId: String) {
            guard !visited.contains(deviceId) else { return }
            guard let device = manager.devices.first(where: { USBDevice.uniqueId($0) == deviceId }) else { return }
            
            sorted.append(device)
            visited.insert(deviceId)
            
            if let children = childrenMap[deviceId] {
                for childId in children {
                    appendFamily(childId)
                }
            }
        }
        
        let heirIds = Set(inheritedDevices.map { $0.deviceId })
        let roots = manager.devices.filter { !heirIds.contains(USBDevice.uniqueId($0)) }
        
        for root in roots {
            appendFamily(USBDevice.uniqueId(root))
        }
        
        for device in manager.devices {
            let id = USBDevice.uniqueId(device)
            if !visited.contains(id) {
                sorted.append(device)
            }
        }
        
        return sorted
    }
    
    func indentLevel(for device: USBDevice) -> CGFloat {
        if (isRenamingDeviceId == USBDevice.uniqueId(device)) {
            return 0;
        }
        var level = 0
        var currentId = USBDevice.uniqueId(device)
        
        while let relation = inheritedDevices.first(where: { $0.deviceId == currentId }) {
            let parentId = relation.inheritsFrom
            
            if manager.devices.contains(where: { USBDevice.uniqueId($0) == parentId }) {
                level += 1
                currentId = parentId
            } else {
                break
            }
        }
        
        let multiply: CGFloat = increasedIndentationGap ? 36 : 16
        return CGFloat(level) * multiply
    }
    
    func goToSettings() {
        if (manager.trafficMonitorRunning) {
            manager.stopEthernetMonitoring()
        }
        if #available(macOS 15.0, *) {
            currentWindow = .settings
        } else {
            openWindow(id: "legacy_settings")
        }
    }
    
    func showEyeSlash() -> Bool {
        if (noTextButtons) {
            return true;
        } else {
            return (!restartButton && !profilerButton);
        }
    }
    
    private func toggleTrafficMonitoring() {
        if (manager.trafficMonitorRunning) {
            manager.stopEthernetMonitoring()
        } else {
            manager.startEthernetMonitoring()
        }
    }
    
    private var noEthernetCableAndNoMonitoring: Bool {
        return !manager.ethernet && trafficMonitorInactive
    }
    
    private var trafficMonitorInactive: Bool {
        return !manager.trafficMonitorRunning
    }
    
    private func mainButtonLabel(_ text: LocalizedStringKey, _ systemImage: String) -> some View {
        if noTextButtons {
            return AnyView(Image(systemName: systemImage))
        } else {
            return AnyView(Label(text, systemImage: systemImage))
        }
    }
    
    private var isRenaming: Bool {
        return isRenamingDeviceId != ""
    }
    
    private var enoughSpaceForActiveTrafficButtonLabel: Bool {
        return !camouflagedIndicator && trafficButtonLabel
    }
    

    func compactStringInformation(_ usb: USBDevice) -> String {
        var parts: [String] = []
        
        if !usb.name.isEmpty {
            parts.append(usb.name)
        } else {
            parts.append(String(localized: "usb_device"))
        }
        
        if let vendor = usb.vendor, !vendor.isEmpty {
            parts.append(vendor)
        }
        
        parts.append(usb.speedDescription)
        
        parts.append(String(format: "%04X:%04X", usb.vendorId, usb.productId))
        
        if let usbVer = usb.usbVersionBCD {
            if let usbVersion = USBDevice.usbVersionLabel(from: usbVer, convertHexa: convertHexa) {
                parts.append("\(String(localized: "usb_version")) \(usbVersion)")
            } else {
                parts.append("\(String(localized: "usb_version")) 0x\(String(format: "%04X", usbVer))")
            }
        }
        
        if let serial = usb.serialNumber, !serial.isEmpty {
            parts.append("\(String(localized: "serial_number")) \(serial)")
        }
        
        if let portMax = usb.portMaxSpeedMbps {
            let portStr = portMax >= 1000
            ? String(format: "%.1f Gbps", Double(portMax) / 1000.0)
            : "\(portMax) Mbps"
            parts.append("\(String(localized: "port_max")) \(portStr)")
        }
        
        return parts.joined(separator: "\n")
    }
    
    func showSecondaryInfo(for device: USBDevice) -> Bool {
        if devicesShowingMore.contains(device) { return true }
        if isRenamingDeviceId == USBDevice.uniqueId(device) { return false }
        if !hideSecondaryInfo { return true }
        return mouseHoverInfo && isHoveringDeviceId == USBDevice.uniqueId(device)
    }
    
    func showTechInfo(for device: USBDevice) -> Bool {
        if devicesShowingMore.contains(device) { return true }
        if isRenamingDeviceId == USBDevice.uniqueId(device) { return false }
        if !hideTechInfo { return true }
        return mouseHoverInfo && isHoveringDeviceId == USBDevice.uniqueId(device)
    }
    
    func searchOnWeb(_ search: String) {
        guard let query = search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(searchEngine.searchURL)\(query)") else {
            return
        }
        openURL(url)
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 6) {
                if manager.devices.isEmpty {
                    ScrollView {
                        Text("no_devices_found")
                            .foregroundStyle(.secondary)
                            .padding(15)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(sortedDevices()) { dev in
                                let uniqueId: String = USBDevice.uniqueId(dev)
                                let indent = disableInheritanceLayout ? 0 : indentLevel(for: dev)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    
                                    HStack {
                                        
                                        if (isRenamingDeviceId == uniqueId) {
                                            CustomTextField(
                                                text: $inputText,
                                                placeholder: String(localized: "insert_new_name"),
                                                maxLength: 30,
                                                isFocused: $textFieldFocused
                                            )
                                            .frame(width: 190)
                                            .help("renaming_help")
                                            
                                            Button(role: .cancel) {
                                                isRenamingDeviceId = ""
                                            } label: {
                                                Text("cancel")
                                            }
                                            
                                            Button("confirm") {
                                                let uniqueId = USBDevice.uniqueId(dev)
                                                if inputText.isEmpty {
                                                    renamedDevices.removeAll { $0.deviceId == uniqueId }
                                                } else {
                                                    renamedDevices.removeAll { $0.deviceId == uniqueId }
                                                    renamedDevices.append(RenamedDevice(deviceId: uniqueId, name: inputText))
                                                }
                                                inputText = ""
                                                isRenamingDeviceId = ""
                                                manager.refresh()
                                            }
                                            .buttonStyle(.borderedProminent)
                                            
                                        } else {
                                            if let device = renamedDevices.first(where: { $0.deviceId == uniqueId }) {
                                                let title: String = renamedIndicator ? "∙ \(device.name)" : device.name
                                                let textView = Text(title)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.primary)
                                                
                                                textView
                                            } else {
                                                let textView = Text(dev.name.isEmpty ? "usb_device" : dev.name)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.primary)
                                                
                                                textView
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        if showSecondaryInfo(for: dev) {
                                            if let vendor = dev.vendor, !vendor.isEmpty {
                                                Text(vendor)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                        
                                    }
                                    .padding(.leading, indent)
                                    .onHover { hovering in
                                        if (mouseHoverInfo) {
                                            if hovering {
                                                isHoveringDeviceId = uniqueId
                                                Utils.hapticFeedback()
                                            } else if isHoveringDeviceId == uniqueId {
                                                isHoveringDeviceId = ""
                                            }
                                        }
                                    }
                                    
                                    if showTechInfo(for: dev) {
                                        HStack {
                                            Text(dev.speedDescription)
                                                .font(.system(size: 9))
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            
                                            if showSecondaryInfo(for: dev) {
                                                Text(String(format: "%04X:%04X", dev.vendorId, dev.productId))
                                                    .font(.system(size: 9))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .padding(.leading, indent)
                                        
                                        HStack {
                                            
                                            if let usbVer = dev.usbVersionBCD {
                                                let usbVersion: String? = USBDevice.usbVersionLabel(from: usbVer, convertHexa: convertHexa)
                                                Text("\(String(localized: "usb_version")) \(usbVersion ?? String(format: "0x%04X", usbVer))")
                                                    .font(.system(size: 9))
                                                    .foregroundStyle(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            if showSecondaryInfo(for: dev) {
                                                if let serial = dev.serialNumber, !serial.isEmpty {
                                                    Text("\(String(localized: "serial_number")) \(serial)")
                                                        .font(.system(size: 9))
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                        }
                                        .padding(.leading, indent)
                                        
                                        if showPortMax {
                                            if let portMax = dev.portMaxSpeedMbps {
                                                Text("\(String(localized: "port_max")) \(portMax >= 1000 ? String(format: "%.1f Gbps", Double(portMax)/1000.0) : "\(portMax) Mbps")")
                                                    .font(.system(size: 9))
                                                    .foregroundStyle(.secondary)
                                                    .padding(.leading, indent)
                                            }
                                        }
                                    }
                                    
                                }
                                .padding(.vertical, 3)
                                .animation(.spring(duration: 0.15), value: showSecondaryInfo(for: dev))
                                .animation(.spring(duration: 0.15), value: showTechInfo(for: dev))
                                .contextMenu {
                                    
                                    Button {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(compactStringInformation(dev), forType: .string)
                                    } label: {
                                        Label("copy", systemImage: "square.on.square")
                                    }
                                    
                                    Button {
                                        inputText = ""
                                        isRenamingDeviceId = uniqueId
                                    } label: {
                                        Label("rename", systemImage: "pencil.and.scribble")
                                    }
                                    
                                    Button(role: .destructive) {
                                        let uniqueId = USBDevice.uniqueId(dev)
                                        let newDevice = CamouflagedDevice(deviceId: uniqueId)
                                        camouflagedDevices.removeAll { $0.deviceId == uniqueId }
                                        camouflagedDevices.append(newDevice)
                                        manager.refresh()
                                    } label: {
                                        Label("hide", systemImage: "eye.slash")
                                    }
                                    .disabled(inheritedDevices.contains { $0.inheritsFrom == USBDevice.uniqueId(dev) })
                                    
                                    if (!mouseHoverInfo && hideTechInfo) {
                                        Divider()
                                        if (!devicesShowingMore.contains(dev)) {
                                            Button {
                                                devicesShowingMore.append(dev)
                                            } label: {
                                                Label("show_more", systemImage: "line.3.horizontal")
                                            }
                                        } else {
                                            Button {
                                                devicesShowingMore.removeAll { $0 == dev }
                                            } label: {
                                                Label("show_less", systemImage: "ellipsis")
                                            }
                                        }
                                    }
                                    
                                    if (!disableContextMenuSearch) {
                                        
                                        Divider()
                                        
                                        Button {
                                            searchOnWeb(dev.name)
                                        } label: {
                                            Label("search_name", systemImage: "globe")
                                        }
                                        
                                        Button {
                                            let id = String(format: "%04X:%04X", dev.vendorId, dev.productId)
                                            searchOnWeb(id)
                                        } label: {
                                            Label("search_id", systemImage: "globe")
                                        }
                                        
                                        Button {
                                            searchOnWeb(dev.serialNumber!)
                                        } label: {
                                            Label("search_sn", systemImage: "globe")
                                        }
                                        .disabled(dev.serialNumber == nil)
                                        
                                    }
                                    
                                }
                                
                                Divider()
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .frame(maxHeight: 1_000)
                }
                
            }
            .padding(3)
            .frame(width: 465, height: windowHeight(longList: longList, compactList: hideTechInfo))
            
            HStack {
                
                if camouflagedIndicator {
                    Group {
                        if (showEyeSlash()) {
                            Image(systemName: "eye.slash")
                        }
                        let first = NumberConverter(manager.connectedCamouflagedDevices).convert()
                        let second = NumberConverter(camouflagedDevices.count).convert()
                        Text("\(first)/\(second)")
                    }
                    .opacity(manager.connectedCamouflagedDevices > 0 ? 0.5 : 0.2)
                    .help("hidden_indicator")
                    .contextMenu {
                        
                        Button {
                            camouflagedIndicator = false
                        } label: {
                            Label("disable_indicator", systemImage: "eye.slash")
                        }
                        
                        Divider()
                        
                        Button {
                            camouflagedDevices.removeAll()
                            manager.refresh()
                        } label: {
                            Label("undo_all", systemImage: "trash")
                        }
                        .disabled(camouflagedDevices.isEmpty)
                        
                    }
                }
                
                Spacer()
                
                if (profilerButton) {
                    Button {
                        Utils.openSysInfo()
                    } label: {
                        if (noTextButtons) {
                            Image(systemName: "info.circle")
                        } else {
                            Label("profiler_abbreviated", systemImage: "info.circle")
                        }
                    }
                }
                
                if (trafficButton) {
                    
                    if (enoughSpaceForActiveTrafficButtonLabel) {
                        if (manager.trafficMonitorRunning) {
                            Label("running", systemImage: "arrow.up.arrow.down")
                                .font(.footnote)
                                .opacity(0.5)
                        } else {
                            Text("paused")
                                .font(.footnote)
                        }
                    }
                    
                    Button {
                        toggleTrafficMonitoring()
                    } label: {
                        Image(systemName: manager.trafficMonitorRunning ? "pause.fill" : "play.fill")
                    }
                    .contextMenu {
                        Button {
                            toggleTrafficMonitoring()
                        } label: {
                            Label("stop_resume", systemImage: "playpause.fill")
                        }
                        .disabled(noEthernetCableAndNoMonitoring)
                        
                        Divider()
                        
                        Button {
                            trafficButton = false;
                        } label: {
                            Label("hide", systemImage: "eye.slash")
                        }
                        
                        Button {
                            trafficButtonLabel = !trafficButtonLabel;
                        } label: {
                            if (!trafficButtonLabel) {
                                Label("show_traffic_side_label", systemImage: "eye")
                            } else {
                                Label("hide_traffic_side_label", systemImage: "eye.slash")
                            }
                        }
                        .disabled(camouflagedIndicator)
                    }
                }
                
                Button {
                    goToSettings()
                } label: {
                    mainButtonLabel("settings", "gear")
                }
                .contextMenu {
                    Button {
                        goToSettings()
                    } label: {
                        Label("open", systemImage: "arrow.up.right.square")
                    }
                    Button {
                        Utils.openSysInfo()
                    } label: {
                        Label("open_profiler", systemImage: "info.circle")
                    }
                    
                    if (showEthernet && internetMonitoring) {
                        
                        Divider()
                        
                        if (trafficMonitorInactive) {
                            Button {
                                manager.startEthernetMonitoring()
                            } label: {
                                Label("resume_traffic_monitor", systemImage: "play.fill")
                            }
                        } else {
                            Button {
                                manager.stopEthernetMonitoring()
                            } label: {
                                Label("stop_traffic_monitor", systemImage: "pause.fill")
                            }
                        }
                    }
                }
                
                Button {
                    manager.refresh()
                } label: {
                    mainButtonLabel("refresh", "arrow.clockwise")
                }
                
                if (restartButton) {
                    Button {
                        Utils.killApp()
                    } label: {
                        mainButtonLabel("restart", "arrow.2.squarepath")
                    }
                }
                
                Button(role: .destructive) {
                    NSApp.terminate(nil)
                } label: {
                    mainButtonLabel("exit", "power")
                }
                .contextMenu {
                    Button {
                        Utils.killApp()
                    } label: {
                        Label("restart", systemImage: "arrow.2.squarepath")
                    }
                }
                
            }
            .padding(10)
            .disabled(isRenaming)
        }
    }
}
