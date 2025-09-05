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
    @Environment(\.openWindow) var openWindow
    
    @AppStorage(StorageKeys.convertHexa) private var convertHexa = false
    @AppStorage(StorageKeys.showPortMax) private var showPortMax = false
    @AppStorage(StorageKeys.longList) private var longList = false
    @AppStorage(StorageKeys.renamedIndicator) private var renamedIndicator = false
    @AppStorage(StorageKeys.camouflagedIndicator) private var camouflagedIndicator = false
    @AppStorage(StorageKeys.hideTechInfo) private var hideTechInfo = false
    
    @CodableAppStorage(StorageKeys.renamedDevices) private var renamedDevices: [RenamedDevice] = []
    @CodableAppStorage(StorageKeys.camouflagedDevices) private var camouflagedDevices: [CamouflagedDevice] = []
    
    func windowHeight(longList: Bool, compactList: Bool) -> CGFloat? {
        if (manager.devices.isEmpty) {
            return nil;
        }
        let baseValue: CGFloat = 200;
        var multiplier: CGFloat = 25;
        if (longList) {
            multiplier = 30;
        }
        if (compactList) {
            multiplier = 12;
        }
        let sum: CGFloat = baseValue + (CGFloat(manager.devices.count) * multiplier);
        var max: CGFloat = 380;
        if (longList) {
            max += 315;
        }
        if (sum >= max) {
            return max;
        } else {
            return sum;
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if manager.devices.isEmpty {
                ScrollView {
                    Text(String(localized: "no_devices_found"))
                        .foregroundStyle(.secondary)
                        .padding(15)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(manager.devices) { dev in
                            let uniqueId: String = USBDevice.uniqueId(dev);
                            VStack(alignment: .leading, spacing: 2) {
                                
                                HStack {
                                    
                                    if let device = renamedDevices.first(where: { $0.deviceId == uniqueId }) {
                                        let title: String = renamedIndicator ? "∙ \(device.name)" : device.name;
                                        Text(title)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.primary)
                                    } else {
                                        Text(dev.name.isEmpty ? String(localized: "usb_device") : dev.name)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Spacer()
                                    
                                    if let vendor = dev.vendor, !vendor.isEmpty {
                                        Text(vendor)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.primary)
                                    }
                                    
                                }
                                
                                if (!hideTechInfo) {
                                    HStack {
                                        Text(dev.speedDescription)
                                            .font(.system(size: 9))
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        
                                        Text(String(format: "%04X:%04X", dev.vendorId, dev.productId))
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    HStack {
                                        
                                        if let usbVer = dev.usbVersionBCD {
                                            Text("\(String(localized: "usb_version")) \(USBDevice.usbVersionLabel(from: usbVer, convertHexa: convertHexa) ?? String(format: "0x%04X", usbVer))")
                                                .font(.system(size: 9))
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if let serial = dev.serialNumber, !serial.isEmpty {
                                            Text("\(String(localized: "serial_number")) \(serial)")
                                                .font(.system(size: 9))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    
                                    if (showPortMax) {
                                        if let portMax = dev.portMaxSpeedMbps {
                                            Text("\(String(localized: "port_max")) \(portMax >= 1000 ? String(format: "%.1f Gbps", Double(portMax)/1000.0) : "\(portMax) Mbps")")
                                                .font(.system(size: 9))
                                                .foregroundStyle(.secondary)
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
        .frame(width: 450, height: windowHeight(longList: longList, compactList: hideTechInfo))
        
        HStack {
            
            if (camouflagedDevices.count > 0 && camouflagedIndicator) {
                Group {
                    Image(systemName: "eye.slash")
                    Text("\(camouflagedDevices.count)")
                }
                .opacity(0.5)
            }
            
            Spacer()
            
            Button {
                openWindow(id: "settings")
            } label: {
                Label(String(localized: "settings"), systemImage: "gear")
            }
            .font(.system(size: 12))
            
            
            Button {
                manager.refresh()
            } label: {
                Label(String(localized: "refresh"), systemImage: "arrow.clockwise")
            }
            .font(.system(size: 12))
            
            Button(role: .destructive) {
                NSApp.terminate(nil)
            } label: {
                Label(String(localized: "exit"), systemImage: "power")
            }
            
            
        }
        .padding(10)
        
    }
}
