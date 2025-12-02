//
//  LogsView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 02/12/25.
//

import SwiftUI

struct LogsView: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    @Binding var currentWindow: AppWindow
    
    @AS(Key.storeConnectionLogs) private var storeConnectionLogs = false
    
    @State private var blink: Bool = false
    @State private var storedNames: Dictionary<String, String> = [:]
    @State private var paintedLogs: [String] = []
    @State private var blacklistedIds: [String] = []
    @State private var recentsOnly: Bool = false
    @State private var recentsAmount: Int = 10
    
    private var totalValidLogs: Int {
        CSM.ConnectionLog.items
            .filter { !blacklistedIds.contains($0.deviceId) }
            .count
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func onlyNumbers(_ text: String) -> String {
        return text.filter { $0.isNumber }
    }
    
    private func deviceName(_ id: String) -> String? {
        
        let dictName = storedNames[id]
        
        if id == "power" {
            return "power_supply".localized
        }
        
        if dictName != nil {
            return dictName
        }
        
        let renamedName = CSM.Renamed[id]?.name
        
        if renamedName != nil {
            return renamedName
        }
        
        let storedName = CSM.Stored[id]?.name
        
        if storedName != nil {
            return storedName
        }
        
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
        case 95:
            recentsAmount = 10
        case 10:
            recentsAmount = 20
        case 20:
            recentsAmount = 30
        case 30:
            recentsAmount = 50
        case 50:
            recentsAmount = 80
        case 80:
            recentsAmount = 95
        default:
            break
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
            let time: Date
            let action: String
        }

        let transformed: [ExportLog] = CSM.ConnectionLog.items.map { log in
            ExportLog(
                name: deviceName(log.deviceId) ?? "UNKNOWN_DEVICE",
                time: log.time,
                action: log.disconnect ? "disconnect" : "connect"
            )
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(transformed)

            let panel = NSSavePanel()
            panel.title = "export_connection_logs".localized
            panel.message = "choose_where_to_save_exported_json".localized
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = "file".localized.lowercased() + ".json"

            panel.begin { response in
                if response == .OK, let url = panel.url {
                    do {
                        try data.write(to: url, options: .atomic)
                    } catch {
                        print("Error:", error)
                    }
                }
            }

        } catch {
            print("Error encoding logs:", error)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack {
                Text("connection_logs")
                    .font(.title2)
                    .bold()
                
                if storeConnectionLogs == false {
                    Image(systemName: "pause.fill")
                        .foregroundStyle(.red)
                        .opacity(blink ? 0.40 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: blink)
                }
                
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
                    ForEach(allLogsSorted) { log in
                        
                        let isPainted = paintedLogs.contains(log.id)
                        
                        HStack {
                            Text(deviceName(log.deviceId) ?? "device".localized)
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Spacer()
                            
                            Text(formatDate(log.time))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Image(systemName: log.disconnect ? "arrowshape.right.fill" : "arrowshape.left.fill")
                                .foregroundStyle(log.disconnect ? .red : .green)
                                .frame(width: 7)
                        }
                        .padding(.vertical, 4)
                        .background(isPainted ? .yellow.opacity(0.2) : .clear)
                        .id(log.id)
                        .frame(maxHeight: 90)
                        .contextMenu {
                            
                            Button(isPainted ? "remove_paint" : "paint") {
                                if !isPainted {
                                    paintedLogs.append(log.id)
                                } else {
                                    paintedLogs.removeAll(where: { $0 == log.id })
                                }
                                manager.refresh()
                            }
                            
                            Divider()
                            
                            Button("temporarily_ignore_device_logs") {
                                blacklistedIds.append(log.deviceId)
                            }
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
                
                Button("⇆", action: cycle)
                
                let msg = String(format: NSLocalizedString("show_only_x_logs", comment: "TOGGLE"), "\(recentsAmount)")
                Button(msg) {
                    recentsOnly.toggle()
                    if recentsOnly {
                        CSM.ConnectionLog.keepOnly(last: recentsAmount)
                    }
                    manager.refresh()
                }
                
                Text(recentsOnly ? "on" : "off")
                    .foregroundStyle(recentsOnly ? .green : .red)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    currentWindow = .settings
                } label: {
                    Label("back", systemImage: "arrow.uturn.backward")
                }
                
            }
        }
        .padding(10)
        .frame(minWidth: WindowWidth.value, minHeight: 600)
        .onAppear {
            blink.toggle()
        }
    }
}
