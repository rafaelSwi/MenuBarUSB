//
//  LogsView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 02/12/25.
//

import SwiftUI

struct LogsView: View {
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var manager: USBDeviceManager
    @Binding var currentWindow: AppWindow
    
    let window: Bool
    
    @AS(Key.storeConnectionLogs) private var storeConnectionLogs = false
    
    @State private var storedNames: Dictionary<String, String> = [:]
    @State private var paintedLogs: [String] = []
    @State private var blacklistedIds: [String] = []
    @State private var recentsOnly: Bool = false
    @State private var recentsAmount: Int = 10
    @State private var showTimeDifferences: Bool = false
    
    private var totalValidLogs: Int {
        CSM.ConnectionLog.items
            .filter { !blacklistedIds.contains($0.deviceId) }
            .count
    }
    
    private func formatDateSimple(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy HH:mm:ss:ms"
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"

        if calendar.isDateInToday(date) {
            let todayString = "today".localized
            return "\(todayString) \(timeFormatter.string(from: date))"
        }

        if calendar.isDateInYesterday(date) {
            let yesterdayString = "yesterday".localized
            return "\(yesterdayString) \(timeFormatter.string(from: date))"
        }

        let normalFormatter = DateFormatter()
        normalFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return normalFormatter.string(from: date)
    }
    
    private func formatDifference(from: Date?, to: Date?) -> String {
        guard let from, let to else {
            return "unknown".localized
        }

        let interval = to.timeIntervalSince(from)
        let totalMilliseconds = Int(abs(interval * 1000))
        
        let h = totalMilliseconds / 3_600_000
        let m = (totalMilliseconds % 3_600_000) / 60_000
        let s = (totalMilliseconds % 60_000) / 1000
        let ms = totalMilliseconds % 1000
        
        var parts: [String] = []
        
        if h > 0 { parts.append("\(h)h") }
        if m > 0 || h > 0 { parts.append("\(m)m") }
        if s > 0 || m > 0 || h > 0 { parts.append("\(s)s") }
        
        parts.append("\(ms)ms")
        
        return parts.joined(separator: " ")
    }
    
    private func onlyNumbers(_ text: String) -> String {
        return text.filter { $0.isNumber }
    }
    
    private func deviceName(_ id: String) -> String? {
        let dictName = storedNames[id]
        if id == "power" { return "power_supply".localized }
        if dictName != nil { return dictName }
        let renamedName = CSM.Renamed[id]?.name
        if renamedName != nil { return renamedName }
        let storedName = CSM.Stored[id]?.name
        if storedName != nil { return storedName }
        let name = manager.devices.first(where: { $0.item.uniqueId == id })?.item.name
        if name != nil {
            DispatchQueue.main.async {
                storedNames[id] = name
            }
        }
        return name
    }
    
    private func cycle () {
        defer {
            if recentsOnly {
                CSM.ConnectionLog.keepOnly(last: recentsAmount)
                manager.refresh()
            }
        }
        switch recentsAmount {
        case 95: recentsAmount = 10
        case 10: recentsAmount = 20
        case 20: recentsAmount = 30
        case 30: recentsAmount = 50
        case 50: recentsAmount = 80
        case 80: recentsAmount = 95
        default: break
        }
    }
    
    private var allLogsSorted: [DeviceConnectionLog] {
        return CSM.ConnectionLog.items
            .reversed()
            .filter { !blacklistedIds.contains($0.deviceId) }
    }
    
    private func exportAllLogsToJSON() {

        struct ExportLog: Codable {
            let name: String
            let time: String
            let connect: Bool
            let disposableId: String
        }

        struct ExportDevice: Codable {
            let disposableId: String
            let name: String
            let vendor: String?
            let vendorId: Int
            let productId: Int
            let serialNumber: String?
            let locationId: UInt32?
            let speedMbps: Int?
            let portMaxSpeedMbps: Int?
            let usbVersionBCD: Int?
        }
        
        struct Metadata: Codable {
            let exportedAt: String
            let machineModel: String
            let osVersion: String
            let appVersion: String
        }

        struct ExportData: Codable {
            let metadata: Metadata
            let devices: [ExportDevice]
            let logs: [ExportLog]
        }

        var idMap: [String: String] = [:]

        for log in CSM.ConnectionLog.items {
            if idMap[log.deviceId] == nil {
                idMap[log.deviceId] = UUID().uuidString
            }
        }

        let logsTransformed: [ExportLog] = CSM.ConnectionLog.items.map { log in
            ExportLog(
                name: deviceName(log.deviceId) ?? "UNKNOWN_DEVICE",
                time: formatDateSimple(log.time),
                connect: !log.disconnect,
                disposableId: idMap[log.deviceId] ?? "UNKNOWN"
            )
        }

        let devicesTransformed: [ExportDevice] = manager.devices.map { wrapper in

            let devIdKey: String = {
                if let loc = wrapper.item.locationId {
                    if idMap[String(loc)] != nil { return String(loc) }
                }
                if idMap[wrapper.item.id.uuidString] != nil {
                    return wrapper.item.id.uuidString
                }
                if idMap[wrapper.item.uniqueId] != nil {
                    return wrapper.item.uniqueId
                }
                return UUID().uuidString
            }()

            let disposableId = idMap[devIdKey] ?? UUID().uuidString

            return ExportDevice(
                disposableId: disposableId,
                name: wrapper.item.name,
                vendor: wrapper.item.vendor,
                vendorId: wrapper.item.vendorId,
                productId: wrapper.item.productId,
                serialNumber: wrapper.item.serialNumber,
                locationId: wrapper.item.locationId,
                speedMbps: wrapper.item.speedMbps,
                portMaxSpeedMbps: wrapper.item.portMaxSpeedMbps,
                usbVersionBCD: wrapper.item.usbVersionBCD
            )
        }

        let exportedAt = formatDateSimple(Date())
        let v = ProcessInfo.processInfo.operatingSystemVersion
        let appVersion = Utils.App.appVersion
        
        let osVersion = "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"

        let machineModel: String = {
            var size = 0
            sysctlbyname("hw.model", nil, &size, nil, 0)
            var model = [CChar](repeating: 0, count: size)
            sysctlbyname("hw.model", &model, &size, nil, 0)
            return String(cString: model)
        }()

        
        let metadata = Metadata(exportedAt: exportedAt, machineModel: machineModel, osVersion: osVersion, appVersion: appVersion)
        let exportObject = ExportData(
            metadata: metadata,
            devices: devicesTransformed,
            logs: logsTransformed
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(exportObject)

            let panel = NSSavePanel()
            panel.title = "export_connection_logs".localized
            panel.message = "choose_where_to_save_exported_json".localized
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = "file".localized.lowercased() + ".json"

            panel.begin { response in
                if response == .OK, let url = panel.url {
                    try? data.write(to: url, options: .atomic)
                }
            }
        } catch {
            print("Failed to export logs: \(error)")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack {
                Text("connection_logs")
                    .font(.title2)
                    .bold()
                
                Image(systemName: "power.circle.fill")
                    .foregroundStyle(storeConnectionLogs ? .green : .red)
                    .onTapGesture { storeConnectionLogs.toggle() }
                
                Spacer()
                
                Group {
                    Button {
                        CSM.ConnectionLog.clear()
                        manager.refresh()
                    } label: {
                        Label("\(totalValidLogs)", systemImage: "trash")
                    }
                    .foregroundStyle(.red)
                    
                    Button {
                        exportAllLogsToJSON()
                    } label: {
                        Label("export", systemImage: "document")
                    }
                }
                .disabled(CSM.ConnectionLog.count <= 0)
            }
            
            ScrollViewReader { proxy in
                List {
                    ForEach(Array(allLogsSorted.enumerated()), id: \.element.id) { index, log in
                        
                        let isPainted = paintedLogs.contains(log.id)
                        let previousLog = index < allLogsSorted.count - 1 ? allLogsSorted[index + 1] : nil
                        let showDiff = showTimeDifferences && previousLog != nil
                        
                        HStack {
                            Text(deviceName(log.deviceId) ?? "device".localized)
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Spacer()
                            
                            Text(formatDate(log.time))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            let color = log.disconnect ? AssetColors.logDisconnect : AssetColors.logConnect
                            Image(systemName: log.disconnect ? "arrowshape.right.fill" : "arrowshape.left.fill")
                                .foregroundStyle(color)
                                .frame(width: 7)
                        }
                        .padding(.vertical, 4)
                        .background(isPainted ? .yellow.opacity(0.2) : .clear)
                        .id(log.id)
                        .frame(maxHeight: 10)
                        .contextMenu {
                            Button(isPainted ? "remove_paint" : "paint") {
                                if !isPainted { paintedLogs.append(log.id) }
                                else { paintedLogs.removeAll(where: { $0 == log.id }) }
                                manager.refresh()
                            }
                            
                            Divider()
                            
                            Button("temporarily_ignore_device_logs") {
                                blacklistedIds.append(log.deviceId)
                            }
                        }
                        
                        if showDiff {
                            let diff = formatDifference(from: previousLog!.time, to: log.time)
                            Text("﹡ " + "time_interval".localized + ": \(diff)")
                                .font(.system(size: 11, weight: .light))
                                .foregroundStyle(.secondary)
                        }
                        
                    }
                    
                    Color.clear
                        .frame(height: 1)
                        .id("BOTTOM")
                }
                .onChange(of: allLogsSorted.count) { _ in
                    if recentsOnly {
                        CSM.ConnectionLog.keepOnly(last: recentsAmount)
                    }
                    withAnimation {
                        proxy.scrollTo(allLogsSorted.first?.time.timeIntervalSince1970, anchor: .top)
                    }
                }
            }
            
            HStack {
                
                Button("＋", action: cycle)
                
                let msg = String(format: NSLocalizedString("show_only_x_logs", comment: "TOGGLE"), "\(recentsAmount)")
                Button(msg) {
                    recentsOnly.toggle()
                    if recentsOnly {
                        CSM.ConnectionLog.keepOnly(last: recentsAmount)
                    }
                    manager.refresh()
                }
                
                Text(recentsOnly ? "on" : "off")
                    .foregroundStyle(recentsOnly ? .green : .secondary)
                    .fontWeight(.bold)
                    .onTapGesture {
                        recentsOnly.toggle()
                    }
                
                Spacer()
                
                Button {
                    showTimeDifferences.toggle()
                } label: {
                    Image(systemName: "clock")
                }
                .foregroundStyle(showTimeDifferences ? .green : .secondary)
                .help("toggle_time_interval")
                
                if window {
                    Button {
                        blacklistedIds.removeAll()
                        paintedLogs.removeAll()
                    } label: {
                        Image(systemName: "eraser")
                    }
                    .disabled(blacklistedIds.isEmpty && paintedLogs.isEmpty)
                    Button("close") { dismiss() }
                } else {
                    Button {
                        currentWindow = .settings
                    } label: {
                        Label("back", systemImage: "arrow.uturn.backward")
                    }
                }
            }
        }
        .padding(10)
        .frame(minWidth: WindowWidth.value, minHeight: 600)
    }
}
