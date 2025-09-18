//
//  MenuBarUSBApp.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import SwiftUI
import ServiceManagement

@main
struct MenuBarUSBApp: App {
    
    @StateObject private var manager = USBDeviceManager()
    
    @State var currentWindow: AppWindow = .devices
    
    @AppStorage(StorageKeys.reduceTransparency) private var reduceTransparency = false
    
    var body: some Scene {
        MenuBarExtra {
            switch (self.currentWindow) {
            case .devices:
                ContentView(currentWindow: $currentWindow)
                    .appBackground(reduceTransparency)
                    .environmentObject(manager)
            case .settings:
                SettingsView(currentWindow: $currentWindow)
                    .appBackground(reduceTransparency)
                    .environmentObject(manager)
            case .donate:
                DonateView(currentWindow: $currentWindow)
                    .appBackground(reduceTransparency)
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "cable.connector")
                Text(String(manager.devices.count))
            }
        }
        .menuBarExtraStyle(.window)
        
    }
}

