//
//  MenuBarUSBApp.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import ServiceManagement
import SwiftUI

@main
struct MenuBarUSBApp: App {
    @StateObject private var manager = USBDeviceManager()
    @State private var currentWindow: AppWindow = .devices
    @State private var convertedCount: String = ""

    @AppStorage(Key.reduceTransparency) private var isReduceTransparencyOn = false
    @AppStorage(Key.forceDarkMode) private var forceDarkMode = false
    @AppStorage(Key.forceLightMode) private var forceLightMode = false
    @AppStorage(Key.hideCount) private var hideCount = false
    @AppStorage(Key.hideMenubarIcon) private var hideMenubarIcon = false
    @AppStorage(Key.macBarIcon) private var macBarIcon: String = "cable.connector"
    @AppStorage(Key.showEthernet) private var showEthernet = false
    @AppStorage(Key.newVersionNotification) private var newVersionNotification = false
    
    init() {
        if newVersionNotification {
            Task {
                if (await Utils.App.hasUpdate()) {
                    Utils.System.sendNotification(title: "update_notification_title", body: "update_notification_body")
                }
            }
        }
    }

    private var countText: some View {
        func updateCount() {
            convertedCount = NumberConverter(manager.devices.count).convert()
        }

        return Text(convertedCount)
            .onAppear(perform: updateCount)
            .onChange(of: manager.devices) { _ in updateCount() }
    }

    private var menuLabel: some View {
        return HStack(spacing: 5) {
            let image = HStack(spacing: 7) {
                Image(manager.ethernetTraffic ? "ETHERNET_DOT" : "ETHERNET")
                Image(systemName: macBarIcon)
            }
            .asImage()

            var ethernetCableConnectedAndShowEthernet: Bool {
                return showEthernet && manager.ethernetCableConnected
            }

            if !hideMenubarIcon {
                if ethernetCableConnectedAndShowEthernet { Image(nsImage: image) }
                Image(systemName: macBarIcon)
            }
            if !hideCount { countText }
        }
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
            LegacySettingsView()
        }
    }

    private func view<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .appBackground(isReduceTransparencyOn)
            .colorSchemeForce(light: forceLightMode, dark: forceDarkMode)
            .environmentObject(manager)
    }

    @ViewBuilder
    private var mainContent: some View {
        switch currentWindow {
        case .devices:
            view { ContentView(currentWindow: $currentWindow) }
        case .settings:
            view { SettingsView(currentWindow: $currentWindow) }
        case .donate:
            view { DonateView(currentWindow: $currentWindow) }
        case .heritage:
            view { HeritageView(currentWindow: $currentWindow) }
        case .inheritanceTree:
            view { InheritanceTreeView(currentWindow: $currentWindow) }
        }
    }
}
