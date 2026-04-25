//
//  MainListBottomBarContextMenuTraffic.swift
//  MenuBarUSB
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct MainListBottomBarContextMenuTraffic: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    
    @AS(Key.disableTrafficButtonLabel) private var disableTrafficButtonLabel = false
    @AS(Key.camouflagedIndicator) private var camouflagedIndicator = false
    @AS(Key.trafficButton) private var trafficButton = false

    private func toggleTrafficMonitoring() {
        if manager.trafficMonitorRunning {
            manager.stopEthernetMonitoring()
        } else {
            manager.startEthernetMonitoring()
        }
    }
    
    private var noEthernetCableAndNoMonitoring: Bool {
        return !manager.ethernetCableConnected && !manager.trafficMonitorRunning
    }
    
    var body: some View {
        let status = LocalizedStringKey(manager.trafficMonitorRunning ? "running" : "paused")
        Text("status") + Text(" ") + Text(status)

        Divider()

        Button {
            toggleTrafficMonitoring()
        } label: {
            Label("stop_resume", systemImage: "playpause.fill")
        }
        .disabled(noEthernetCableAndNoMonitoring)

        Divider()

        Button {
            disableTrafficButtonLabel.toggle()
        } label: {
            if disableTrafficButtonLabel {
                Label("show_traffic_side_label", systemImage: "eye")
            } else {
                Label("hide_traffic_side_label", systemImage: "eye.slash")
            }
        }
        .disabled(camouflagedIndicator)

        Divider()

        Button {
            trafficButton = false
        } label: {
            Label("hide_button", systemImage: "eye.slash")
        }
    }
}
