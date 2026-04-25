//
//  MainListDeviceList.swift
//  MenuBarUSB
//
//  Created by rafael on 19/04/26.
//

import SwiftUI

struct MainListDeviceList: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    @Environment(\.openURL) var openURL
    
    @State private var toolbarItemHelp: String = ""
    @State private var inputText: String = ""
    @State private var isHoveringDeviceId: String = ""
    @State private var textFieldFocused: Bool = false
    @State private var isHoveringPowerSupply: Bool = false
    @State private var devicesShowingMore: [USBDeviceWrapper] = []
    
    @Binding var isRenamingDeviceId: String
    
    @AS(Key.powerSourceInfo) private var powerSourceInfo = false
    @AS(Key.indexIndicator) private var indexIndicator = false
    @AS(Key.powerSupplyAsCharger) private var powerSupplyAsCharger = false
    @AS(Key.renamedIndicator) private var renamedIndicator = false
    @AS(Key.hideSecondaryInfo) private var hideSecondaryInfo = false
    @AS(Key.hidePinIndicator) private var hidePinIndicator = false
    @AS(Key.mouseHoverInfo) private var mouseHoverInfo = false
    @AS(Key.showPortMax) private var showPortMax = false
    @AS(Key.storedIndicator) private var storedIndicator = false
    @AS(Key.showScrollBar) private var showScrollBar = false
    @AS(Key.hideTechInfo) private var hideTechInfo = false
    @AS(Key.disableInheritanceLayout) private var disableInheritanceLayout = false
    @AS(Key.increasedIndentationGap) private var increasedIndentationGap = false
    @AS(Key.disableContextMenuSearch) private var disableContextMenuSearch = false
    @AS(Key.disableContextMenuHeritage) private var disableContextMenuHeritage = false
    @AS(Key.bigNames) private var bigNames = false
    @AS(Key.storeDevices) private var storeDevices = false
    @AS(Key.playHardwareSound) private var playHardwareSound = false
    @AS(Key.hardwareSound) private var hardwareSound: String = ""
    @AS(Key.searchEngine) private var searchEngine: SearchEngine = .google
    
    private var sortedDevices: [USBDeviceWrapper] {
        var childrenMap: [String: [String]] = [:]
        for relation in CSM.Heritage.devices {
            childrenMap[relation.inheritsFrom, default: []].append(relation.deviceId)
        }

        func buildFamilyTree(root: USBDeviceWrapper,
                             deviceDict: [String: USBDeviceWrapper]) -> [USBDeviceWrapper]
        {
            var result: [USBDeviceWrapper] = []
            result.append(root)

            if let children = childrenMap[root.item.uniqueId] {
                let sortedChildren = children.sorted { idA, idB in
                    let favA = isPinned(idA)
                    let favB = isPinned(idB)

                    if favA != favB { return favA }
                    return false
                }

                for childId in sortedChildren {
                    if let child = deviceDict[childId] {
                        result.append(contentsOf: buildFamilyTree(root: child, deviceDict: deviceDict))
                    }
                }
            }

            return result
        }

        let deviceDict = Dictionary(manager.devices.map { ($0.item.uniqueId, $0) },
                                    uniquingKeysWith: { first, _ in first })

        let heirIds = Set(CSM.Heritage.devices.map { $0.deviceId })

        let roots = manager.devices.filter { !heirIds.contains($0.item.uniqueId) }

        var families: [[USBDeviceWrapper]] = []
        for root in roots {
            families.append(buildFamilyTree(root: root, deviceDict: deviceDict))
        }

        let sortedFamilies = families.sorted { famA, famB in
            let rootA = famA.first!
            let rootB = famB.first!
            let favA = isPinned(rootA.item.uniqueId)
            let favB = isPinned(rootB.item.uniqueId)

            if favA != favB { return favA }
            return false
        }

        return sortedFamilies.flatMap { $0 }
    }
    
    private func devicesShowingMoreHas(_ device: borrowing USBDevice) -> Bool {
        for dev in devicesShowingMore {
            if dev.item.id == device.id {
                return true
            }
        }
        return false
    }
    
    private func isPinned(_ id: String) -> Bool {
        return CSM.Pin[id] != nil
    }

    private func isRenaming(device id: String) -> Bool {
        return isRenamingDeviceId == id
    }
    
    private var showChargingStatus: Bool {
        return powerSourceInfo && manager.chargeConnected && manager.chargePercentage != nil
    }
    
    private var powerSupplyLabel: String {
        powerSupplyAsCharger ? "charger".localized : "power_supply".localized
    }
    
    private func showSecondaryInfo(for device: borrowing USBDevice, charger _: Bool = false) -> Bool {
        if devicesShowingMoreHas(device) { return true }
        if isRenamingDeviceId == device.uniqueId { return false }
        if !hideSecondaryInfo { return true }
        return mouseHoverInfo && isHoveringDeviceId == device.uniqueId
    }

    private var showBatteryPercentage: Bool {
        if !hideSecondaryInfo { return true }
        return isHoveringPowerSupply
    }

    private func showTechInfo(for device: borrowing USBDevice) -> Bool {
        if devicesShowingMoreHas(device) { return true }
        if isRenamingDeviceId == device.uniqueId { return false }
        if !hideTechInfo { return true }
        return mouseHoverInfo && isHoveringDeviceId == device.uniqueId
    }

    private func showDisconnectedText(for deviceId: String) -> Bool {
        if isRenamingDeviceId == deviceId { return false }
        return !hideTechInfo || isHoveringDeviceId == deviceId
    }
    
    private func indexIndicatorView(_ index: Int, force: Bool = false) -> some View {
        var value: Int = index
        if showChargingStatus {
            value += 2
        } else {
            value += 1
        }
        return Text("\(force ? index : value)")
            .font(.footnote)
            .foregroundStyle(.gray)
    }
    
    private func deviceTitleView(_ name: String?, deviceId: String) -> some View {
        let renamed = CSM.Renamed.devices.first { $0.deviceId == deviceId }
        let pinned = CSM.Pin.devices.first { $0.deviceId == deviceId }

        let baseName = renamed?.name ?? name ?? "usb_device".localized

        let title = renamedIndicator && renamed != nil
            ? "✏ \(baseName)"
            : baseName

        var showIsPinnedByHover: Bool {
            let pin = pinned != nil
            let hovering = isHoveringDeviceId == deviceId
            return pin && hovering && hideTechInfo && mouseHoverInfo
        }

        var showPinIcon: Bool {
            return pinned != nil && !hidePinIndicator && !showIsPinnedByHover
        }

        return HStack {
            if showPinIcon {
                Image(systemName: "pin.fill")
                    .frame(width: 8, height: 8)
            }

            Text(title)
                .font(.system(size: bigNames ? 18 : 12, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)

            if showIsPinnedByHover {
                Text("pinned")
                    .fontWeight(.bold)
                    .font(.system(size: 8.5, weight: .semibold))
                    .opacity(0.7)
            }
        }
    }
    
    private func searchOnWeb(_ search: String) {
        guard let query = search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(searchEngine.searchURL)\(query)")
        else {
            return
        }
        openURL(url)
    }
    
    private func deviceRenameView(deviceId: String) -> some View {
        return HStack {
            CustomTextField(
                text: $inputText,
                placeholder: "insert_new_name",
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
                let uniqueId = deviceId
                if inputText.isEmpty {
                    CSM.Renamed.remove(withId: uniqueId)
                } else {
                    CSM.Renamed.add(deviceId, inputText)
                }
                inputText = ""
                isRenamingDeviceId = ""
                manager.refresh()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func deviceId(_ device: borrowing USBDevice) -> String {
        return String(format: "%04X:%04X", device.vendorId, device.productId)
    }
    
    private func indentLevel(for device: borrowing USBDevice) -> CGFloat {
        if isRenamingDeviceId == device.uniqueId {
            return 0
        }
        var level = 0
        var currentId = device.uniqueId

        while let relation = CSM.Heritage.devices.first(where: { $0.deviceId == currentId }) {
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
    
    
    var body: some View {
        if showChargingStatus {
            HStack {
                if indexIndicator {
                    indexIndicatorView(1, force: true)
                }
                Group {
                    Text(powerSupplyLabel)
                        .font(.system(size: bigNames ? 18 : 12, weight: .semibold))
                    Spacer()
                    if showBatteryPercentage {
                        Image(systemName: manager.chargePercentage == 100 ? "battery.100percent" : "bolt.fill")
                            .font(.system(size: 10))
                        Text("\(manager.chargePercentage ?? 0)%")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .foregroundColor(.primary)
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)
            .onHover { hovering in
                if mouseHoverInfo {
                    if hovering {
                        isHoveringPowerSupply = true
                        Utils.System.hapticFeedback()
                    } else if isHoveringPowerSupply {
                        isHoveringPowerSupply = false
                    }
                }
            }
            .contextMenu {
                MainListDeviceListContextMenuCharger()
            }

            Divider()
        }
        ScrollView(showsIndicators: showScrollBar) {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(Array(sortedDevices.enumerated()), id: \.element.id) { index, device in
                    let uniqueId: String = device.item.uniqueId
                    let indent = disableInheritanceLayout ? 0 : indentLevel(for: device.item)

                    LazyVStack(alignment: .leading, spacing: 2) {
                        HStack {
                            if isRenaming(device: uniqueId) {
                                deviceRenameView(deviceId: uniqueId)
                            } else {
                                if indexIndicator {
                                    indexIndicatorView(index)
                                }
                                deviceTitleView(device.item.name, deviceId: uniqueId)
                            }

                            Spacer()

                            if showSecondaryInfo(for: device.item) {
                                if let vendor = device.item.vendor, !vendor.isEmpty {
                                    Text(vendor)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
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
                                    .lineLimit(1)
                                Spacer()

                                if showSecondaryInfo(for: device.item) {
                                    Text(deviceId(device.item))
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.leading, indent)

                            HStack {
                                if let usbVer = device.item.usbVersionBCD {
                                    let usbVersion: String? = Utils.USB.usbVersionLabel(from: usbVer)
                                    Text("\("usb_version".localized) \(usbVersion ?? String(format: "0x%04X", usbVer))")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                if showSecondaryInfo(for: device.item) {
                                    if let serial = device.item.serialNumber, !serial.isEmpty {
                                        Text("\("serial_number".localized) \(serial)")
                                            .font(.system(size: 9))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(.leading, indent)

                            if showPortMax {
                                if let portMax = device.item.portMaxSpeedMbps {
                                    Text("\("port_max".localized) \(portMax >= 1000 ? String(format: "%.1f Gbps", Double(portMax) / 1000.0) : "\(portMax) Mbps")")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                        .padding(.leading, indent)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 3)
                    .animation(.spring(duration: 0.15), value: showSecondaryInfo(for: device.item))
                    .animation(.spring(duration: 0.15), value: showTechInfo(for: device.item))
                    .contextMenu {
                        MainListDeviceListContextMenuDevice(
                            inputText: $inputText,
                            isRenamingDeviceId: $isRenamingDeviceId,
                            devicesShowingMore: $devicesShowingMore,
                            device: device,
                            sortedDevices: sortedDevices,
                            searchOnWeb: searchOnWeb(_:)
                        )
                    }

                    Divider()
                }
                if storeDevices {
                    ForEach(CSM.Stored.filteredDevices(manager.devices)) { device in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                if storedIndicator {
                                    Image("offline")
                                        .renderingMode(.template)
                                        .resizable()
                                        .frame(width: 14, height: 14)
                                        .scaledToFit()
                                        .padding(3)
                                }
                                if isRenaming(device: device.deviceId) {
                                    deviceRenameView(deviceId: device.deviceId)
                                } else {
                                    deviceTitleView(device.name, deviceId: device.deviceId)
                                }
                                Spacer()
                            }
                            if showDisconnectedText(for: device.deviceId) {
                                Text("disconnected")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .opacity(isRenaming(device: device.deviceId) ? 1.0 : 0.5)
                        .padding(.top, 3)
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
                            MainListDeviceListContextMenuOfflineDevice(
                                inputText: $inputText,
                                isRenamingDeviceId: $isRenamingDeviceId,
                                storedDevice: device
                            )
                        }
                        Divider()
                            .padding(.top, 3)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxHeight: 1000)
    }
}
