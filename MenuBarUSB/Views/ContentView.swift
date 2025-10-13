//
//  ContentView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject var manager: USBDeviceManager
    @Environment(\.openURL) var openURL

    @State private var isHoveringDeviceId: String = ""
    @State private var isRenamingDeviceId: String = ""
    @State private var inputText: String = ""
    @State private var textFieldFocused: Bool = false
    @State private var devicesShowingMore: [USBDeviceWrapper] = []

    @Binding var currentWindow: AppWindow

    @AppStorage(Key.convertHexa) private var convertHexa = false
    @AppStorage(Key.showPortMax) private var showPortMax = false
    @AppStorage(Key.longList) private var longList = false
    @AppStorage(Key.renamedIndicator) private var renamedIndicator = false
    @AppStorage(Key.camouflagedIndicator) private var camouflagedIndicator = false
    @AppStorage(Key.hideTechInfo) private var hideTechInfo = false
    @AppStorage(Key.disableInheritanceLayout) private var disableInheritanceLayout = false
    @AppStorage(Key.increasedIndentationGap) private var increasedIndentationGap = false
    @AppStorage(Key.hideSecondaryInfo) private var hideSecondaryInfo = false
    @AppStorage(Key.noTextButtons) private var noTextButtons = false
    @AppStorage(Key.restartButton) private var restartButton = false
    @AppStorage(Key.mouseHoverInfo) private var mouseHoverInfo = false
    @AppStorage(Key.profilerButton) private var profilerButton = false
    @AppStorage(Key.disableContextMenuSearch) private var disableContextMenuSearch = false
    @AppStorage(Key.showEthernet) private var showEthernet = false
    @AppStorage(Key.internetMonitoring) private var internetMonitoring = false
    @AppStorage(Key.trafficButton) private var trafficButton = false
    @AppStorage(Key.disableTrafficButtonLabel) private var disableTrafficButtonLabel = false
    @AppStorage(Key.contextMenuCopyAll) private var contextMenuCopyAll = false
    @AppStorage(Key.storeDevices) private var storeDevices = false
    @AppStorage(Key.storedIndicator) private var storedIndicator = false
    @AppStorage(Key.searchEngine) private var searchEngine: SearchEngine = .google

    @CodableAppStorage(Key.inheritedDevices) private var inheritedDevices: [HeritageDevice] = []

    private func windowHeight(longList: Bool, compactList: Bool) -> CGFloat? {
        if isTrulyEmpty {
            return nil
        }
        let baseValue: CGFloat = 200
        var multiplier: CGFloat = 25
        if longList {
            multiplier = 30
        }
        if compactList {
            multiplier = 12
        }
        
        var total = manager.devices.count
        if (storeDevices) {
            total += CodableStorageManager.Stored.filteredDevices(manager.devices).count
        }
        
        let sum: CGFloat = baseValue + (CGFloat(total) * multiplier)
        var max: CGFloat = 380
        if longList {
            max += 315
        }
        return sum >= max ? max : sum
    }

    private func sortedDevices() -> [USBDeviceWrapper] {
        var sorted: [USBDeviceWrapper] = []
        var visited: Set<String> = []

        var childrenMap: [String: [String]] = [:]
        for relation in inheritedDevices {
            childrenMap[relation.inheritsFrom, default: []].append(relation.deviceId)
        }

        func appendFamily(_ deviceId: String) {
            guard !visited.contains(deviceId) else { return }
            guard let device = manager.devices.first(where: { $0.item.uniqueId == deviceId }) else { return }

            sorted.append(device)
            visited.insert(deviceId)

            if let children = childrenMap[deviceId] {
                for childId in children {
                    appendFamily(childId)
                }
            }
        }

        let heirIds = Set(inheritedDevices.map { $0.deviceId })
        let roots = manager.devices.filter { !heirIds.contains($0.item.uniqueId) }

        for root in roots {
            appendFamily(root.item.uniqueId)
        }

        for device in manager.devices {
            let id = device.item.uniqueId
            if !visited.contains(id) {
                sorted.append(device)
            }
        }

        return sorted
    }

    private func indentLevel(for device: borrowing USBDevice) -> CGFloat {
        if isRenamingDeviceId == device.uniqueId {
            return 0
        }
        var level = 0
        var currentId = device.uniqueId

        while let relation = inheritedDevices.first(where: { $0.deviceId == currentId }) {
            let parentId = relation.inheritsFrom

            if manager.devices.contains(where: { $0.item.uniqueId == parentId }) {
                level += 1
                currentId = parentId
            } else {
                break
            }
        }

        let multiply: CGFloat = increasedIndentationGap ? 36 : 16
        return CGFloat(level) * multiply
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

    private func toggleTrafficMonitoring() {
        if manager.trafficMonitorRunning {
            manager.stopEthernetMonitoring()
        } else {
            manager.startEthernetMonitoring()
        }
    }
    
    private func mainButtonLabel(_ text: LocalizedStringKey, _ systemImage: String) -> some View {
        if noTextButtons {
            return AnyView(Image(systemName: systemImage))
        } else {
            return AnyView(Label(text, systemImage: systemImage))
        }
    }
    
    private var showEyeSlash: Bool {
        if noTextButtons {
            return true
        } else {
            return !restartButton && !profilerButton
        }
    }

    private var noEthernetCableAndNoMonitoring: Bool {
        return !manager.ethernetCableConnected && trafficMonitorInactive
    }

    private var trafficMonitorInactive: Bool {
        return !manager.trafficMonitorRunning
    }

    private var isRenaming: Bool {
        return isRenamingDeviceId != ""
    }

    private var showTrafficButtonLabel: Bool {
        return !camouflagedIndicator && !disableTrafficButtonLabel
    }

    private var trafficMonitorOn: Bool {
        return showEthernet && internetMonitoring
    }
    
    private func deviceId(_ device: borrowing USBDevice) -> String {
        return String(format: "%04X:%04X", device.vendorId, device.productId)
    }
    
    private func copyTextLabelView(_ text: String) -> some View {
        let copy = String(localized: "copy")
        let item = String(localized: "\(text)")
        let label = "\(copy): \(item)"
        return Label(label, systemImage: "square.on.square")
    }

    private func compactStringInformation(_ device: borrowing USBDevice) -> String {
        var parts: [String] = []

        if !device.name.isEmpty {
            parts.append(device.name)
        } else {
            parts.append(String(localized: "usb_device"))
        }

        if let vendor = device.vendor, !vendor.isEmpty {
            parts.append(vendor)
        }

        parts.append(device.uniqueId)

        parts.append(deviceId(device))

        if let usbVer = device.usbVersionBCD {
            if let usbVersion = Utils.USB.usbVersionLabel(from: usbVer, convertHexa: convertHexa) {
                parts.append("\(String(localized: "usb_version")) \(usbVersion)")
            } else {
                parts.append("\(String(localized: "usb_version")) 0x\(String(format: "%04X", usbVer))")
            }
        }

        if let serial = device.serialNumber, !serial.isEmpty {
            parts.append("\(String(localized: "serial_number")) \(serial)")
        }

        if let portMax = device.portMaxSpeedMbps {
            let portStr = portMax >= 1000
                ? String(format: "%.1f Gbps", Double(portMax) / 1000.0)
                : "\(portMax) Mbps"
            parts.append("\(String(localized: "port_max")) \(portStr)")
        }

        return parts.joined(separator: "\n")
    }

    private func devicesShowingMoreHas(_ device: borrowing USBDevice) -> Bool {
        for dev in devicesShowingMore {
            if dev.item.id == device.id {
                return true
            }
        }
        return false
    }

    private func showSecondaryInfo(for device: borrowing USBDevice) -> Bool {
        if devicesShowingMoreHas(device) { return true }
        if isRenamingDeviceId == device.uniqueId { return false }
        if !hideSecondaryInfo { return true }
        return mouseHoverInfo && isHoveringDeviceId == device.uniqueId
    }

    private func showTechInfo(for device: borrowing USBDevice) -> Bool {
        if devicesShowingMoreHas(device) { return true }
        if isRenamingDeviceId == device.uniqueId { return false }
        if !hideTechInfo { return true }
        return mouseHoverInfo && isHoveringDeviceId == device.uniqueId
    }

    private func searchOnWeb(_ search: String) {
        guard let query = search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(searchEngine.searchURL)\(query)")
        else {
            return
        }
        openURL(url)
    }
    
    private var isTrulyEmpty: Bool {
        let connectedCount: Int = manager.devices.count
        let storedCount: Int = CodableStorageManager.Stored.filteredDevices(manager.devices).count
        
        if (connectedCount == 0 && storeDevices == false) {
            return true
        }
        
        if (connectedCount == 0 && storedCount == 0) {
            return true
        }
        
        return false
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 6) {
                if isTrulyEmpty {
                    ScrollView {
                        Text("no_devices_found")
                            .foregroundStyle(.secondary)
                            .padding(15)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(sortedDevices()) { device in
                                let uniqueId: String = device.item.uniqueId
                                let indent = disableInheritanceLayout ? 0 : indentLevel(for: device.item)

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        if isRenamingDeviceId == uniqueId {
                                            CustomTextField(
                                                text: $inputText,
                                                placeholder: String(localized: "insert_new_name"),
                                                maxLength: 30,
                                                isFocused: $textFieldFocused
                                            )
                                            .frame(width: 190)
                                            .help("renaming_help")

                                            Button(role: .cancel) {
                                                isRenamingDeviceId = ""
                                            } label: {
                                                Text("cancel")
                                            }

                                            Button("confirm") {
                                                let uniqueId = device.item.uniqueId
                                                if inputText.isEmpty {
                                                    CodableStorageManager.Renamed.remove(withId: uniqueId)
                                                } else {
                                                    CodableStorageManager.Renamed.add(device, inputText)
                                                }
                                                inputText = ""
                                                isRenamingDeviceId = ""
                                                manager.refresh()
                                            }
                                            .buttonStyle(.borderedProminent)

                                        } else {
                                            if let device = CodableStorageManager.Renamed.devices.first(where: { $0.deviceId == uniqueId }) {
                                                let title: String = renamedIndicator ? "∙ \(device.name)" : device.name
                                                let textView = Text(title)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.primary)

                                                textView
                                            } else {
                                                let textView = Text(device.item.name.isEmpty ? "usb_device" : device.item.name)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.primary)

                                                textView
                                            }
                                        }

                                        Spacer()

                                        if showSecondaryInfo(for: device.item) {
                                            if let vendor = device.item.vendor, !vendor.isEmpty {
                                                Text(vendor)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                    }
                                    .padding(.leading, indent)
                                    .onHover { hovering in
                                        if mouseHoverInfo {
                                            if hovering {
                                                isHoveringDeviceId = uniqueId
                                                Utils.System.hapticFeedback()
                                            } else if isHoveringDeviceId == uniqueId {
                                                isHoveringDeviceId = ""
                                            }
                                        }
                                    }

                                    if showTechInfo(for: device.item) {
                                        HStack {
                                            Text(device.item.speedDescription)
                                                .font(.system(size: 9))
                                                .foregroundStyle(.secondary)
                                            Spacer()

                                            if showSecondaryInfo(for: device.item) {
                                                Text(deviceId(device.item))
                                                    .font(.system(size: 9))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .padding(.leading, indent)

                                        HStack {
                                            if let usbVer = device.item.usbVersionBCD {
                                                let usbVersion: String? = Utils.USB.usbVersionLabel(from: usbVer, convertHexa: convertHexa)
                                                Text("\(String(localized: "usb_version")) \(usbVersion ?? String(format: "0x%04X", usbVer))")
                                                    .font(.system(size: 9))
                                                    .foregroundStyle(.secondary)
                                            }

                                            Spacer()

                                            if showSecondaryInfo(for: device.item) {
                                                if let serial = device.item.serialNumber, !serial.isEmpty {
                                                    Text("\(String(localized: "serial_number")) \(serial)")
                                                        .font(.system(size: 9))
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                        }
                                        .padding(.leading, indent)

                                        if showPortMax {
                                            if let portMax = device.item.portMaxSpeedMbps {
                                                Text("\(String(localized: "port_max")) \(portMax >= 1000 ? String(format: "%.1f Gbps", Double(portMax) / 1000.0) : "\(portMax) Mbps")")
                                                    .font(.system(size: 9))
                                                    .foregroundStyle(.secondary)
                                                    .padding(.leading, indent)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 3)
                                .animation(.spring(duration: 0.15), value: showSecondaryInfo(for: device.item))
                                .animation(.spring(duration: 0.15), value: showTechInfo(for: device.item))
                                .contextMenu {
                                    Button {
                                        Utils.System.copyToClipboard(compactStringInformation(device.item))
                                    } label: {
                                        Label("copy", systemImage: "square.on.square")
                                    }

                                    Button {
                                        inputText = ""
                                        isRenamingDeviceId = uniqueId
                                    } label: {
                                        Label("rename", systemImage: "pencil.and.scribble")
                                    }

                                    Button {
                                        CodableStorageManager.Camouflaged.add(device)
                                        manager.refresh()
                                    } label: {
                                        Label("hide", systemImage: "eye.slash")
                                    }
                                    .disabled(inheritedDevices.contains { $0.inheritsFrom == device.item.uniqueId })

                                    if !mouseHoverInfo && hideTechInfo {
                                        Divider()
                                        if !devicesShowingMoreHas(device.item) {
                                            Button {
                                                devicesShowingMore.append(device)
                                            } label: {
                                                Label("show_more", systemImage: "line.3.horizontal")
                                            }
                                        } else {
                                            Button {
                                                devicesShowingMore.removeAll { $0 == device }
                                            } label: {
                                                Label("show_less", systemImage: "ellipsis")
                                            }
                                        }
                                    }
                                    
                                    if (contextMenuCopyAll) {
                                        Divider()
                                        
                                        Button {
                                            Utils.System.copyToClipboard(device.item.name)
                                        } label: {
                                            copyTextLabelView(device.item.name)
                                        }
                                        
                                        Button {
                                            Utils.System.copyToClipboard(device.item.vendor ?? "?")
                                        } label: {
                                            copyTextLabelView(device.item.vendor ?? "?")
                                        }
                                        .disabled(device.item.vendor == nil)
                                        
                                        Button {
                                            Utils.System.copyToClipboard(deviceId(device.item))
                                        } label: {
                                            copyTextLabelView(deviceId(device.item))
                                        }
                                        
                                        Button {
                                            Utils.System.copyToClipboard(device.item.serialNumber ?? "SN")
                                        } label: {
                                            copyTextLabelView(device.item.serialNumber ?? "SN")
                                        }
                                        .disabled(device.item.serialNumber == nil)
                                        
                                    }

                                    if !disableContextMenuSearch {
                                        Divider()

                                        Button {
                                            searchOnWeb(device.item.name)
                                        } label: {
                                            Label("search_name", systemImage: "globe")
                                        }

                                        Button {
                                            let id = String(format: "%04X:%04X", device.item.vendorId, device.item.productId)
                                            searchOnWeb(id)
                                        } label: {
                                            Label("search_id", systemImage: "globe")
                                        }

                                        Button {
                                            searchOnWeb(device.item.serialNumber!)
                                        } label: {
                                            Label("search_sn", systemImage: "globe")
                                        }
                                        .disabled(device.item.serialNumber == nil)
                                    }
                                }

                                Divider()
                            }
                            if (storeDevices) {
                                ForEach(CodableStorageManager.Stored.filteredDevices(manager.devices)) { device in
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            if (storedIndicator) {
                                                Image("offline")
                                                    .renderingMode(.template)
                                                    .resizable()
                                                    .frame(width: 14, height: 14)
                                                    .scaledToFit()
                                                    .padding(3)
                                            }
                                            Text(device.name)
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                        }
                                        if (!hideTechInfo || isHoveringDeviceId == device.deviceId) {
                                            Text("disconnected")
                                                .font(.system(size: 9))
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Divider()
                                            .padding(.top, 3)
                                    }
                                    .opacity(0.5)
                                    .padding(.vertical, 3)
                                    .onHover { hovering in
                                        if mouseHoverInfo {
                                            if hovering {
                                                isHoveringDeviceId = device.deviceId
                                                Utils.System.hapticFeedback()
                                            } else if isHoveringDeviceId == device.deviceId {
                                                isHoveringDeviceId = ""
                                            }
                                        }
                                    }
                                    .contextMenu {
                                        Button {
                                            manager.refresh()
                                        } label: {
                                            Label("refresh", systemImage: "arrow.clockwise")
                                        }
                                        Divider()
                                        Button {
                                            CodableStorageManager.Stored.remove(withId: device.deviceId)
                                            manager.refresh()
                                        } label: {
                                            Label("remove_from_history", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .frame(maxHeight: 1000)
                }
            }
            .padding(3)
            .frame(width: 465, height: windowHeight(longList: longList, compactList: hideTechInfo))

            HStack {
                if camouflagedIndicator {
                    Group {
                        if showEyeSlash {
                            Image(systemName: "eye.slash")
                        }
                        let first = NumberConverter(manager.connectedCamouflagedDevices).convert()
                        let second = NumberConverter(CodableStorageManager.Camouflaged.devices.count).convert()
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
                            CodableStorageManager.Camouflaged.clear()
                            manager.refresh()
                        } label: {
                            Label("make_all_visible_again", systemImage: "eye")
                        }
                        .disabled(CodableStorageManager.Camouflaged.devices.isEmpty)
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
                        if (showTrafficButtonLabel) {
                            Label(
                                manager.trafficMonitorRunning ? "running" : "paused",
                                systemImage: manager.trafficMonitorRunning ? "stop.fill" : "waveform.badge.magnifyingglass"
                            )
                        } else {
                            Image(systemName: manager.trafficMonitorRunning ? "stop.fill" : "waveform.badge.magnifyingglass")
                        }
                    }
                    .contextMenu {
                        let status =  LocalizedStringKey(manager.trafficMonitorRunning ? "running" : "paused")
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
                        goToSettings()
                    } label: {
                        Label("open", systemImage: "arrow.up.right.square")
                    }
                    Button {
                        Utils.System.openSysInfo()
                    } label: {
                        Label("open_profiler", systemImage: "info.circle")
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

                if restartButton {
                    Button { Utils.App.restart() } label: {
                        mainButtonLabel("restart", "arrow.2.squarepath")
                    }
                    .contextMenu {
                        Button { restartButton = false } label: {
                            Label("hide_button", systemImage: "eye.slash")
                        }
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
            .padding(10)
            .disabled(isRenaming)
        }
    }
}
