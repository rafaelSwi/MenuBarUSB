//
//  ContentView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    
    @State private var isHoveringDeviceId: String = ""
    
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
    
    func showEyeSlash() -> Bool {
        if (noTextButtons) {
            return true;
        } else {
            return (!restartButton && !profilerButton);
        }
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
        if !hideSecondaryInfo { return true }
        return mouseHoverInfo && isHoveringDeviceId == USBDevice.uniqueId(device)
    }
    
    func showTechInfo(for device: USBDevice) -> Bool {
        if !hideTechInfo { return true }
        return mouseHoverInfo && isHoveringDeviceId == USBDevice.uniqueId(device)
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
                                    
                                    if showTechInfo(for: dev) {
                                        HStack {
                                            Text(dev.speedDescription)
                                                .font(.system(size: 9))
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            
                                            if showSecondaryInfo(for: dev) {
                                                Text(String(format: "%04X:%04X", dev.vendorId, dev.productId))
                                                    .font(.system(size: 10))
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
                                .onHover { hovering in
                                    if hovering {
                                        isHoveringDeviceId = uniqueId
                                    } else if isHoveringDeviceId == uniqueId {
                                        isHoveringDeviceId = ""
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
                
                Button {
                    currentWindow = .settings
                } label: {
                    if (noTextButtons) {
                        Image(systemName: "gear")
                    } else {
                        Label("settings", systemImage: "gear")
                    }
                }
                
                Button {
                    manager.refresh()
                } label: {
                    if (noTextButtons) {
                        Image(systemName: "arrow.clockwise")
                    } else {
                        Label("refresh", systemImage: "arrow.clockwise")
                    }
                }
                
                if (restartButton) {
                    Button {
                        Utils.killApp()
                    } label: {
                        if (noTextButtons) {
                            Image(systemName: "arrow.2.squarepath")
                        } else {
                            Label("restart", systemImage: "arrow.2.squarepath")
                        }
                    }
                }
                
                Button(role: .destructive) {
                    NSApp.terminate(nil)
                } label: {
                    if (noTextButtons) {
                        Image(systemName: "power")
                    } else {
                        Label("exit", systemImage: "power")
                    }
                }
                
            }
            .padding(10)
        }
    }
}
