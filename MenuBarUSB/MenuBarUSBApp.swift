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
    @State private var currentWindow: AppWindow = .devices
    @State private var convertedCount: String = ""
    
    @AppStorage(StorageKeys.reduceTransparency) private var isReduceTransparencyOn = false
    @AppStorage(StorageKeys.forceDarkMode) private var forceDarkMode = false
    @AppStorage(StorageKeys.forceLightMode) private var forceLightMode = false
    @AppStorage(StorageKeys.hideCount) private var hideCount = false
    @AppStorage(StorageKeys.hideMenubarIcon) private var hideMenubarIcon = false
    @AppStorage(StorageKeys.macBarIcon) private var macBarIcon: String = "cable.connector"
    @AppStorage(StorageKeys.showEthernet) private var showEthernet = false
    
    private var countText: some View {
        Text(convertedCount)
            .onAppear(perform: updateCount)
            .onChange(of: manager.devices) { _ in updateCount() }
    }
    
    private var menuLabel: some View {
        HStack(spacing: 5) {
            
            let image = HStack(spacing: 7) {
                if manager.ethernetTraffic {
                    Image(systemName: "arrow.up.arrow.down")
                }
                Image("ETHERNET")
                Image(systemName: macBarIcon)
            }
            .asImage()
            
            if !hideMenubarIcon {
                if showEthernet && manager.ethernet == true { Image(nsImage: image) }
                Image(systemName: macBarIcon)
            }
            if !hideCount { countText }
        }
    }
    
    private func updateCount() {
        convertedCount = NumberConverter(manager.devices.count).convert()
    }
    
    var body: some Scene {
        
        MenuBarExtra {
            mainContent
        } label: {
            HStack {
                menuLabel
            }
        }
        .menuBarExtraStyle(.window)
        
        Window("legacy_settings", id: "legacy_settings") {
            LegacySettingsView(currentWindow: $currentWindow)
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        
        switch currentWindow {
        case .devices:
            ContentView(currentWindow: $currentWindow)
                .appBackground(isReduceTransparencyOn)
                .colorSchemeForce(light: forceLightMode, dark: forceDarkMode)
                .environmentObject(manager)
            
        case .settings:
            SettingsView(currentWindow: $currentWindow)
                .appBackground(isReduceTransparencyOn)
                .colorSchemeForce(light: forceLightMode, dark: forceDarkMode)
                .environmentObject(manager)
            
        case .donate:
            DonateView(currentWindow: $currentWindow)
                .appBackground(isReduceTransparencyOn)
                .colorSchemeForce(light: forceLightMode, dark: forceDarkMode)
            
        case .heritage:
            HeritageView(currentWindow: $currentWindow)
                .appBackground(isReduceTransparencyOn)
                .colorSchemeForce(light: forceLightMode, dark: forceDarkMode)
                .environmentObject(manager)
            
        case .inheritanceTree:
            InheritanceTreeView(currentWindow: $currentWindow)
                .appBackground(isReduceTransparencyOn)
                .colorSchemeForce(light: forceLightMode, dark: forceDarkMode)
                .environmentObject(manager)
        }
    }
}
