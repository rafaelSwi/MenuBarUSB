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

    private var trafficMonitorOn: Bool {
        return showEthernet && internetMonitoring
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
    
    private var noEthernetCableAndNoMonitoring: Bool {
        return !manager.ethernetCableConnected && trafficMonitorInactive
    }
    
    private var isTrulyEmpty: Bool {
        let connectedCount: Int = manager.count
        let storedCount: Int = CSM.Stored.filteredDevices(manager.devices).count

        if connectedCount == 0 && storeDevices == false {
            return true
        }

        if connectedCount == 0 && storedCount == 0 {
            return true
        }

        return false
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
                    Button {
                        camouflagedIndicator = false
                    } label: {
                        Label("disable_indicator", systemImage: "eye.slash")
                    }

                    Divider()

                    Button {
                        CSM.Camouflaged.clear()
                        manager.refresh()
                    } label: {
                        Label("make_all_visible_again", systemImage: "eye")
                    }
                    .disabled(CSM.Camouflaged.devices.isEmpty)
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
                                Button {
                                    profilerButton = false
                                } label: {
                                    Label("hide_button", systemImage: "eye.slash")
                                }
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

            Button {
                goToSettings()
            } label: {
                mainButtonLabel("settings", "gear")
            }
            .contextMenu {
                Button {
                    listToolBar.toggle()
                } label: {
                    Label(listToolBar ? "hide_toolbar" : "show_toolbar", systemImage: "menubar.arrow.up.rectangle")
                }
                .disabled(isTrulyEmpty)
                Divider()
                Button {
                    Utils.System.openSysInfo()
                } label: {
                    Label("open_profiler", systemImage: "info.circle")
                }
                if #available(macOS 15.0, *) {
                    Button {
                        openWindow(id: "legacy_settings")
                    } label: {
                        Label("open_legacy_settings", systemImage: "gearshape")
                    }
                }

                if trafficMonitorOn {
                    Divider()

                    if trafficMonitorInactive {
                        Button { manager.startEthernetMonitoring() } label: {
                            Label("resume_traffic_monitor", systemImage: "play.fill")
                        }
                        .disabled(!manager.ethernetCableConnected)
                    } else {
                        Button { manager.stopEthernetMonitoring() } label: {
                            Label("stop_traffic_monitor", systemImage: "pause.fill")
                        }
                    }
                }
            }

            Button { manager.refresh() } label: {
                mainButtonLabel("refresh", "arrow.clockwise")
            }
            .contextMenu {
                Button {
                    openWindow(id: "connection_logs")
                } label: {
                    Label("open_separate_window_to_monitor", systemImage: "macwindow.on.rectangle")
                }
            }

            Button { Utils.App.exit() } label: {
                mainButtonLabel("exit", "power")
            }
            .contextMenu {
                Button {
                    Utils.App.restart()
                } label: {
                    Label("restart", systemImage: "arrow.2.squarepath")
                }
            }
        }
    }
}
