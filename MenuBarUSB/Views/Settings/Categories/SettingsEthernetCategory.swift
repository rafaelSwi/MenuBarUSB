//
//  SettingsEthernetCategory.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct SettingsEthernetCategory: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    
    @Binding var currentWindow: AppWindow
    @Binding var activeRowID: UUID?
    
    @State private var showExperimentalEthernet: Bool = false
    
    @AS(Key.showEthernet) private var showEthernet = false
    @AS(Key.internetMonitoring) private var internetMonitoring = false
    @AS(Key.hideMenubarIcon) private var hideMenubarIcon = false
    @AS(Key.trafficButton) private var trafficButton = false
    @AS(Key.disableTrafficButtonLabel) private var disableTrafficButtonLabel = false
    @AS(Key.profilerButton) private var profilerButton = false
    @AS(Key.fastMonitor) private var fastMonitor = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ToggleRow(
                label: "ethernet_connected_icon",
                description: "ethernet_connected_icon_description",
                binding: $showEthernet,
                activeRowID: $activeRowID,
                incompatibilities: nil,
                disabled: hideMenubarIcon,
                onToggle: { value in
                    manager.refresh()
                    if value == false {
                        manager.stopEthernetMonitoring()
                        internetMonitoring = false
                        trafficButton = false
                    }
                }
            )
            
            HStack {
                
                Image(systemName: showExperimentalEthernet ? "chevron.down" : "chevron.right")
                    .frame(width: 22)
                
                Text("experimental_features")
                    .font(.title3)
                    .padding(.top, 12)
                    .padding(.bottom, 7)
                
            }
            .bold()
            .onTapGesture {
                showExperimentalEthernet.toggle()
            }
            
            if showExperimentalEthernet {
                ToggleRow(
                    label: "internet_monitoring_icon",
                    description: "internet_monitoring_icon_description",
                    binding: $internetMonitoring,
                    activeRowID: $activeRowID,
                    incompatibilities: nil,
                    disabled: hideMenubarIcon || !showEthernet,
                    onToggle: { value in
                        if value == true {
                            if manager.ethernetCableConnected {
                                manager.startEthernetMonitoring()
                                currentWindow = .devices
                            }
                        } else {
                            manager.stopEthernetMonitoring()
                            trafficButton = false
                        }
                    }
                )
                ToggleRow(
                    label: "stop_traffic_monitor_button",
                    description: "stop_traffic_monitor_button_description",
                    binding: $trafficButton,
                    activeRowID: $activeRowID,
                    incompatibilities: [profilerButton],
                    disabled: !showEthernet || !internetMonitoring,
                    onToggle: { value in
                        if value == true {
                            profilerButton = false
                        }
                    }
                )
                ToggleRow(
                    label: "stop_traffic_monitor_button_disable_status",
                    description: "stop_traffic_monitor_button_disable_status_description",
                    binding: $disableTrafficButtonLabel,
                    activeRowID: $activeRowID,
                    incompatibilities: [profilerButton],
                    disabled: !showEthernet || !internetMonitoring,
                    onToggle: { _ in }
                )
                ToggleRow(
                    label: "fast_traffic_monitor",
                    description: "fast_traffic_monitor_description",
                    binding: $fastMonitor,
                    activeRowID: $activeRowID,
                    incompatibilities: nil,
                    disabled: !internetMonitoring,
                    onToggle: { _ in }
                )
            }
        }
    }
}
