//
//  ContentView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: USBDeviceManager
    @State private var showingAbout = false
    
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

        func visit(_ device: USBDevice) {
            let id = USBDevice.uniqueId(device)
            guard !visited.contains(id) else { return }
            
            if let parentId = inheritedDevices.first(where: { $0.deviceId == id })?.inheritsFrom,
               let parentDevice = manager.devices.first(where: { USBDevice.uniqueId($0) == parentId }) {
                visit(parentDevice)
            }
            
            sorted.append(device)
            visited.insert(id)
        }
        
        for device in manager.devices {
            visit(device)
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
        
        let multiply: CGFloat = increasedIndentationGap ? 35 : 12
        return CGFloat(level) * multiply
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
                                            Text(title)
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.primary)
                                        } else {
                                            Text(dev.name.isEmpty ? "usb_device" : dev.name)
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.primary)
                                        }
                                        
                                        Spacer()
                                        
                                        if (!hideSecondaryInfo) {
                                            if let vendor = dev.vendor, !vendor.isEmpty {
                                                Text(vendor)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                        
                                    }
                                    .padding(.leading, indent)
                                    
                                    if !hideTechInfo {
                                        HStack {
                                            Text(dev.speedDescription)
                                                .font(.system(size: 9))
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            
                                            if (!hideSecondaryInfo) {
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
                                            
                                            if (!hideSecondaryInfo) {
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
                        Image(systemName: "eye.slash")
                        Text("\(manager.connectedCamouflagedDevices)/\(camouflagedDevices.count)")
                    }
                    .opacity(manager.connectedCamouflagedDevices > 0 ? 0.5 : 0.2)
                }
                
                Spacer()
                
                Button {
                    currentWindow = .settings
                } label: {
                    Label("settings", systemImage: "gear")
                }
                .font(.system(size: 12))
                
                Button {
                    manager.refresh()
                } label: {
                    Label("refresh", systemImage: "arrow.clockwise")
                }
                .font(.system(size: 12))
                
                Button(role: .destructive) {
                    NSApp.terminate(nil)
                } label: {
                    Label("exit", systemImage: "power")
                }
                
            }
            .padding(10)
        }
    }
}
