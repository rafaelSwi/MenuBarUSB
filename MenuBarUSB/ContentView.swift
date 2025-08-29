//
//  ContentView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import SwiftUI
import ServiceManagement

struct ContentView: View {
    @EnvironmentObject var manager: USBDeviceManager
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @State private var showingAbout = false
    @Environment(\.openWindow) var openWindow
    
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
                                    
                                    
                                    Text(String(format: "%04X:%04X", dev.vendorId, dev.productId))
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)

                                }
                                
                                if let vendor = dev.vendor, !vendor.isEmpty {
                                    Text(vendor)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                                if let serial = dev.serialNumber, !serial.isEmpty {
                                    Text("SN: \(serial)")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                }
                                Text(dev.speedDescription)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 3)
                            Divider()
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(maxHeight: 1000)
            }

            
        }
        .padding(3)
        .frame(width: 450)
        
        HStack {
          Toggle(String(localized: "open_on_startup"), isOn: $launchAtLogin)
            .onChange(of: launchAtLogin) { enabled in
              toggleLoginItem(enabled: enabled)
            }
          
         
          Spacer()
         
            Button {
                openWindow(id: "about")
            } label: {
              Label(String(localized: "about"), systemImage: "info.circle")
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
