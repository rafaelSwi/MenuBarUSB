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

    @AS(Key.reduceTransparency) private var isReduceTransparencyOn = false
    @AS(Key.forceDarkMode) private var forceDarkMode = false
    @AS(Key.forceLightMode) private var forceLightMode = false
    @AS(Key.hideCount) private var hideCount = false
    @AS(Key.powerSourceInfo) private var powerSourceInfo = false
    @AS(Key.hideMenubarIcon) private var hideMenubarIcon = false
    @AS(Key.macBarIcon) private var macBarIcon: String = "cable.connector"
    @AS(Key.showEthernet) private var showEthernet = false
    @AS(Key.forceEnglish) private var forceEnglish = false
    @AS(Key.newVersionNotification) private var newVersionNotification = false
    @AS(Key.internetMonitoring) private var internetMonitoring = false

    init() {
        if newVersionNotification {
            Task {
                if await Utils.App.hasUpdate() {
                    Utils.System.sendNotification(
                        title: String(localized: "update_notification_title"),
                        body: String(localized: "update_notification_body")
                    )
                }
            }
        }
    }

    private var countText: some View {
        func updateCount() {
            convertedCount = NumberConverter(manager.count).converted
        }

        return Text(convertedCount)
            .onAppear(perform: updateCount)
            .onChange(of: manager.count) { _ in updateCount() }
    }

    private var menuLabel: some View {
        if #available(macOS 15.0, *) {
            return HStack(spacing: 5) {
                let image = HStack(spacing: 7) {
                    if manager.trafficMonitorRunning == false && internetMonitoring {
                        Image(systemName: "pause.fill")
                    }
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
        } else {
            return HStack(spacing: 5) {
                Image(systemName: macBarIcon)
                countText
            }
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

        Window("settings", id: "legacy_settings") {
            LegacySettingsView()
                .colorSchemeForce(light: false, dark: true)
        }
        .windowStyle(.hiddenTitleBar)
        
        Window("connection_logs", id: "connection_logs") {
            LogsView(currentWindow: $currentWindow, separateWindow: true)
                .colorSchemeForce(light: false, dark: true)
                .environmentObject(manager)
        }
        .windowStyle(.hiddenTitleBar)
    }

    private func view<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .appBackground(isReduceTransparencyOn)
            .colorSchemeForce(light: forceLightMode, dark: forceDarkMode)
            .environmentObject(manager)
            .environment(\.locale, forceEnglish ? Locale(identifier: "en") : Locale.current)
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
        case .logs:
            view { LogsView(currentWindow: $currentWindow, separateWindow: false) }
        }
    }
}
