//
//  MainListBottomBar.swift
//  MenuBarUSB
//
//  Created by rafael on 19/04/26.
//

import SwiftUI

struct MainListBottomBar: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    @Environment(\.openWindow) private var openWindow
    
    @Binding var currentWindow: AppWindow
    
    @AS(Key.renamedIndicator) private var renamedIndicator = false
    @AS(Key.camouflagedIndicator) private var camouflagedIndicator = false
    @AS(Key.noTextButtons) private var noTextButtons = false
    @AS(Key.showEthernet) private var showEthernet = false
    @AS(Key.listToolBar) private var listToolBar = false
    @AS(Key.storeDevices) private var storeDevices = false
    @AS(Key.trafficButton) private var trafficButton = false
    @AS(Key.profilerButton) private var profilerButton = false
    @AS(Key.powerSourceInfo) private var powerSourceInfo = false
    @AS(Key.internetMonitoring) private var internetMonitoring = false
    @AS(Key.disableTrafficButtonLabel) private var disableTrafficButtonLabel = false
    
    private var showTrafficButtonLabel: Bool {
        return !camouflagedIndicator && !disableTrafficButtonLabel
    }
    
    private var showEyeSlash: Bool {
        if noTextButtons {
            return true
        } else {
            return !profilerButton
        }
    }
    
    private func goToSettings() {
        if manager.trafficMonitorRunning {
            manager.stopEthernetMonitoring()
        }
        if #available(macOS 15.0, *) {
            currentWindow = .settings
        } else {
            openWindow(id: "legacy_settings")
        }
    }

    private func mainButtonLabel(_ text: LocalizedStringKey, _ systemImage: String) -> some View {
        if noTextButtons {
            return AnyView(Image(systemName: systemImage))
        } else {
            return AnyView(Label(text, systemImage: systemImage))
        }
    }
    
    private var trafficMonitorInactive: Bool {
        return !manager.trafficMonitorRunning
    }
    
    private func toggleTrafficMonitoring() {
        if manager.trafficMonitorRunning {
            manager.stopEthernetMonitoring()
        } else {
            manager.startEthernetMonitoring()
        }
    }
    
    var body: some View {
        HStack {
            if camouflagedIndicator {
                Group {
                    if showEyeSlash {
                        Image(systemName: "eye.slash")
                    }
                    let first = NumberConverter(manager.connectedCamouflagedDevices).converted
                    let second = NumberConverter(CSM.Camouflaged.devices.count).converted
                    Text("\(first)/\(second)")
                }
                .opacity(manager.connectedCamouflagedDevices > 0 ? 0.5 : 0.2)
                .help("hidden_indicator")
                .contextMenu {
                    MainListBottomBarContextMenuCamouflagedIndicator(camouflagedIndicator: $camouflagedIndicator)
                }
            }

            Spacer()

            if profilerButton {
                Button {
                    Utils.System.openSysInfo()
                } label: {
                    if noTextButtons {
                        Image(systemName: "info.circle")
                    } else {
                        Label("profiler_abbreviated", systemImage: "info.circle")
                            .help("open_profiler")
                            .contextMenu {
                                MainListBottomBarContextMenuProfiler()
                            }
                    }
                }
            }

            if trafficButton {
                Button {
                    toggleTrafficMonitoring()
                } label: {
                    if showTrafficButtonLabel {
                        Label(
                            manager.trafficMonitorRunning ? "running" : "paused",
                            systemImage: manager.trafficMonitorRunning ? "stop.fill" : "waveform.badge.magnifyingglass"
                        )
                    } else {
                        Image(systemName: manager.trafficMonitorRunning ? "stop.fill" : "waveform.badge.magnifyingglass")
                    }
                }
                .contextMenu {
                    MainListBottomBarContextMenuTraffic()
                }
            }

            Button {
                goToSettings()
            } label: {
                mainButtonLabel("settings", "gear")
            }
            .contextMenu {
                MainListBottomBarContextMenuSettings()
            }

            Button { manager.refresh() } label: {
                mainButtonLabel("refresh", "arrow.clockwise")
            }
            .contextMenu {
                MainListBottomBarContextMenuRefresh()
            }

            Button { Utils.App.exit() } label: {
                mainButtonLabel("exit", "power")
            }
            .contextMenu {
                MainListBottomBarContextMenuExit()
            }
        }
    }
}
