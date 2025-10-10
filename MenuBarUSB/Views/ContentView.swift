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
    @State private var devicesShowingMore: [UnsafePointer<USBDevice>] = []
    
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
    
    private func windowHeight(longList: Bool, compactList: Bool) -> CGFloat? {
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
    
    private func sortedDevices() -> [UnsafePointer<USBDevice>] {
        var sorted: [UnsafePointer<USBDevice>] = []
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
    
    private func indentLevel(for device: UnsafePointer<USBDevice>) -> CGFloat {
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
    
    private func goToSettings() {
        if (manager.trafficMonitorRunning) {
            manager.stopEthernetMonitoring()
        }
        if #available(macOS 15.0, *) {
            currentWindow = .settings
        } else {
            openWindow(id: "legacy_settings")
        }
    }
    
    private func showEyeSlash() -> Bool {
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
    
    private var trafficMonitorOn: Bool {
        return showEthernet && internetMonitoring
    }
    

    private func compactStringInformation(_ ptr: UnsafePointer<USBDevice>) -> String {
        var parts: [String] = []
        
        if !ptr.pointee.name.isEmpty {
            parts.append(ptr.pointee.name)
        } else {
            parts.append(String(localized: "usb_device"))
        }
        
        if let vendor = ptr.pointee.vendor, !vendor.isEmpty {
            parts.append(vendor)
        }
        
        parts.append(USBDevice.speedDescription(ptr))
        
        parts.append(String(format: "%04X:%04X", ptr.pointee.vendorId, ptr.pointee.productId))
        
        if let usbVer = ptr.pointee.usbVersionBCD {
            if let usbVersion = USBDevice.usbVersionLabel(from: usbVer, convertHexa: convertHexa) {
                parts.append("\(String(localized: "usb_version")) \(usbVersion)")
            } else {
                parts.append("\(String(localized: "usb_version")) 0x\(String(format: "%04X", usbVer))")
            }
        }
        
        if let serial = ptr.pointee.serialNumber, !serial.isEmpty {
            parts.append("\(String(localized: "serial_number")) \(serial)")
        }
        
        if let portMax = ptr.pointee.portMaxSpeedMbps {
            let portStr = portMax >= 1000
            ? String(format: "%.1f Gbps", Double(portMax) / 1000.0)
            : "\(portMax) Mbps"
            parts.append("\(String(localized: "port_max")) \(portStr)")
        }
        
        return parts.joined(separator: "\n")
    }
    
    private func showSecondaryInfo(for device: UnsafePointer<USBDevice>) -> Bool {
        if devicesShowingMore.contains(device) { return true }
        if isRenamingDeviceId == USBDevice.uniqueId(device) { return false }
        if !hideSecondaryInfo { return true }
        return mouseHoverInfo && isHoveringDeviceId == USBDevice.uniqueId(device)
    }
    
    private func showTechInfo(for device: UnsafePointer<USBDevice>) -> Bool {
        if devicesShowingMore.contains(device) { return true }
        if isRenamingDeviceId == USBDevice.uniqueId(device) { return false }
        if !hideTechInfo { return true }
        return mouseHoverInfo && isHoveringDeviceId == USBDevice.uniqueId(device)
    }
    
    private func searchOnWeb(_ search: String) {
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
                            ForEach(sortedDevices(), id: \.self) { ptr in
                                let uniqueId: String = USBDevice.uniqueId(ptr)
                                let indent = disableInheritanceLayout ? 0 : indentLevel(for: ptr)
                                
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
                                                let uniqueId = USBDevice.uniqueId(ptr)
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
                                                let textView = Text(ptr.pointee.name.isEmpty ? "usb_device" : ptr.pointee.name)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.primary)
                                                
                                                textView
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        if showSecondaryInfo(for: ptr) {
                                            if let vendor = ptr.pointee.vendor, !vendor.isEmpty {
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
                                    
                                    if showTechInfo(for: ptr) {
                                        HStack {
                                            Text(USBDevice.speedDescription(ptr))
                                                .font(.system(size: 9))
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            
                                            if showSecondaryInfo(for: ptr) {
                                                Text(String(format: "%04X:%04X", ptr.pointee.vendorId, ptr.pointee.productId))
                                                    .font(.system(size: 9))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .padding(.leading, indent)
                                        
                                        HStack {
                                            
                                            if let usbVer = ptr.pointee.usbVersionBCD {
                                                let usbVersion: String? = USBDevice.usbVersionLabel(from: usbVer, convertHexa: convertHexa)
                                                Text("\(String(localized: "usb_version")) \(usbVersion ?? String(format: "0x%04X", usbVer))")
                                                    .font(.system(size: 9))
                                                    .foregroundStyle(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            if showSecondaryInfo(for: ptr) {
                                                if let serial = ptr.pointee.serialNumber, !serial.isEmpty {
                                                    Text("\(String(localized: "serial_number")) \(serial)")
                                                        .font(.system(size: 9))
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                        }
                                        .padding(.leading, indent)
                                        
                                        if showPortMax {
                                            if let portMax = ptr.pointee.portMaxSpeedMbps {
                                                Text("\(String(localized: "port_max")) \(portMax >= 1000 ? String(format: "%.1f Gbps", Double(portMax)/1000.0) : "\(portMax) Mbps")")
                                                    .font(.system(size: 9))
                                                    .foregroundStyle(.secondary)
                                                    .padding(.leading, indent)
                                            }
                                        }
                                    }
                                    
                                }
                                .padding(.vertical, 3)
                                .animation(.spring(duration: 0.15), value: showSecondaryInfo(for: ptr))
                                .animation(.spring(duration: 0.15), value: showTechInfo(for: ptr))
                                .contextMenu {
                                    
                                    Button {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(compactStringInformation(ptr), forType: .string)
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
                                        let uniqueId = USBDevice.uniqueId(ptr)
                                        let newDevice = CamouflagedDevice(deviceId: uniqueId)
                                        camouflagedDevices.removeAll { $0.deviceId == uniqueId }
                                        camouflagedDevices.append(newDevice)
                                        manager.refresh()
                                    } label: {
                                        Label("hide", systemImage: "eye.slash")
                                    }
                                    .disabled(inheritedDevices.contains { $0.inheritsFrom == USBDevice.uniqueId(ptr) })
                                    
                                    if (!mouseHoverInfo && hideTechInfo) {
                                        Divider()
                                        if (!devicesShowingMore.contains(ptr)) {
                                            Button {
                                                devicesShowingMore.append(ptr)
                                            } label: {
                                                Label("show_more", systemImage: "line.3.horizontal")
                                            }
                                        } else {
                                            Button {
                                                devicesShowingMore.removeAll { $0 == ptr }
                                            } label: {
                                                Label("show_less", systemImage: "ellipsis")
                                            }
                                        }
                                    }
                                    
                                    if (!disableContextMenuSearch) {
                                        
                                        Divider()
                                        
                                        Button {
                                            searchOnWeb(ptr.pointee.name)
                                        } label: {
                                            Label("search_name", systemImage: "globe")
                                        }
                                        
                                        Button {
                                            let id = String(format: "%04X:%04X", ptr.pointee.vendorId, ptr.pointee.productId)
                                            searchOnWeb(id)
                                        } label: {
                                            Label("search_id", systemImage: "globe")
                                        }
                                        
                                        Button {
                                            searchOnWeb(ptr.pointee.serialNumber!)
                                        } label: {
                                            Label("search_sn", systemImage: "globe")
                                        }
                                        .disabled(ptr.pointee.serialNumber == nil)
                                        
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
                            Label("paused", systemImage: "pause")
                                .font(.footnote)
                                .opacity(0.5)
                                .help("required_ethernet_to_monitor_traffic")
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
                    
                    if (trafficMonitorOn) {
                        
                        Divider()
                        
                        if (trafficMonitorInactive) {
                            Button {
                                manager.startEthernetMonitoring()
                            } label: {
                                Label("resume_traffic_monitor", systemImage: "play.fill")
                            }
                            .disabled(!manager.ethernet)
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
                    .contextMenu {
                        Button {
                            restartButton = false;
                        } label: {
                            Label("hide", systemImage: "eye.slash")
                        }
                    }
                }
                
                Button {
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
