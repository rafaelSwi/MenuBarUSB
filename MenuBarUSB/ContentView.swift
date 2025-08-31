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
    
    func windowHeight(longList: Bool) -> CGFloat? {
        if (manager.devices.isEmpty) {
            return nil;
        }
        let baseValue: CGFloat = 200;
        let sum: CGFloat = baseValue + (CGFloat(manager.devices.count) * 25);
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
                            VStack(alignment: .leading, spacing: 2) {
                                
                                HStack {
                                    Text(dev.name.isEmpty ? String(localized: "usb_device") : dev.name)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if let vendor = dev.vendor, !vendor.isEmpty {
                                        Text(vendor)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.primary)
                                    }
                                    
                                }
                                
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
        .frame(width: 450, height: windowHeight(longList: longList))
        
        HStack {
            
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
