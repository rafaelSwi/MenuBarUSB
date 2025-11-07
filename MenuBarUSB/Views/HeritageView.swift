//
//  HeritageView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth Swierczynski on 20/09/25.
//

import SwiftUI

struct HeritageView: View {
    enum Step: Int {
        case beginning = 0
        case selectingRole = 1
        case selectingSecondDevice = 2
        case final = 3
    }
    
    enum DeviceRole {
        case nothing
        case willGiveInheritance
        case willReceiveInheritance
    }
    
    @EnvironmentObject var manager: USBDeviceManager
    
    @State private var step: Step = .beginning
    @State private var role: DeviceRole = .nothing
    
    @State private var tryingToDeleteAllInheritances = false
    
    @Binding var currentWindow: AppWindow
    
    @State private var selectedDevice: USBDeviceWrapper?
    @State private var anotherSelectedDevice: USBDeviceWrapper?
    
    private func inheritanceStatus(for deviceId: String?) -> String {
        if (deviceId == nil) { return String(localized: "no_info") }
        
        let inheritsFrom = CSM.Heritage.devices.contains { $0.deviceId == deviceId }
        let hasHeirs =  CSM.Heritage.devices.contains { $0.inheritsFrom == deviceId }
        
        let st = String(localized: "status") + " "

        if inheritsFrom && hasHeirs {
            return st + String(localized: "both_inheriting_and_being_inherited")
        } else if inheritsFrom {
            return st + String(localized: "inheriting_from_another")
        } else if hasHeirs {
            return st + String(localized: "passing_inheritance_to_others")
        } else {
            return st + String(localized: "this_device_has_no_inheritance_ties")
        }
    }

    private var canConfirmInheritance: Bool {
        
        let masterId: String
        let heirId: String

        if role == .willGiveInheritance {
            masterId = selectedDevice?.item.uniqueId ?? ""
            heirId = anotherSelectedDevice?.item.uniqueId ?? ""
        } else {
            masterId = anotherSelectedDevice?.item.uniqueId ?? ""
            heirId = selectedDevice?.item.uniqueId ?? ""
        }

        if masterId == heirId { return false }
        
        if let parent = CSM.Heritage[masterId]?.inheritsFrom,
           parent == heirId { return false }

        var currentId = masterId
        while let parent = CSM.Heritage[currentId]?.inheritsFrom {
            if parent == heirId { return false }
            currentId = parent
        }

        return true
    }

    private func deleteAllInheritances() {
        defer { resetPageState() }
        CSM.Heritage.clear()
    }
    
    private func resetPageState() {
        selectedDevice = nil
        anotherSelectedDevice = nil
        tryingToDeleteAllInheritances = false
        role = .nothing
        step = .beginning
    }
    
    private func confirmInheritance() {
        defer { resetPageState() }
        var uniqueIdMaster: String
        var uniqueIdHeir: String

        switch role {
        case .nothing: return
        case .willGiveInheritance:
            uniqueIdMaster = selectedDevice!.item.uniqueId
            uniqueIdHeir = anotherSelectedDevice!.item.uniqueId
        case .willReceiveInheritance:
            uniqueIdMaster = anotherSelectedDevice!.item.uniqueId
            uniqueIdHeir = selectedDevice!.item.uniqueId
        }

        CSM.Heritage.add(withId: uniqueIdHeir, inheritsFrom: uniqueIdMaster)
    }

    var body: some View {
        VStack(alignment: .leading) {
            
            let placeholder: String = String(localized: "device")
            
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {

                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(localized: "select_device"))
                            .font(.headline)

                        Menu {
                            ForEach(manager.devices, id: \.self) { device in
                                let name = CSM.Renamed[device.item.uniqueId]?.name ?? device.item.name
                                Button(name) {
                                    selectedDevice = device
                                    step = .selectingRole
                                    role = .nothing
                                    anotherSelectedDevice = nil
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedDevice?.item.name ?? placeholder)
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 6).stroke(.gray))
                        }
                        .disabled(manager.devices.isEmpty)

                        if let selectedDevice {
                            Text(inheritanceStatus(for: selectedDevice.item.uniqueId))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if (manager.devices.isEmpty) {
                        Text("no_devices_found")
                    }

                    if step.rawValue > Step.beginning.rawValue {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("this_device")
                                .font(.headline)

                            HStack {
                                Image(systemName: role == .willGiveInheritance ? "checkmark.circle.fill" : "circle")
                                Button("will_be_the_master") {
                                    role = .willGiveInheritance
                                    step = .selectingSecondDevice
                                    anotherSelectedDevice = nil
                                }
                            }

                            HStack {
                                Image(systemName: role == .willReceiveInheritance ? "checkmark.circle.fill" : "circle")
                                Button("is_inheriting_from_some_device") {
                                    role = .willReceiveInheritance
                                    step = .selectingSecondDevice
                                    anotherSelectedDevice = nil
                                }
                            }
                        }
                        .padding(.top, 8)
                    }

                    if step.rawValue > Step.selectingRole.rawValue {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(role == .willGiveInheritance ? "which_one_will_be_the_heir" : "which_device_is_it_inheriting_from")
                                .font(.headline)

                            Menu {
                                ForEach(manager.devices, id: \.self) { device in
                                    Button(CSM.Renamed[device.item.uniqueId]?.name ?? device.item.name) {
                                        anotherSelectedDevice = device
                                        step = .final
                                    }
                                }
                            } label: {
                                Text(anotherSelectedDevice?.item.name ?? placeholder)
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 6).stroke(.gray))
                            }

                            if let anotherSelectedDevice {
                                Text(inheritanceStatus(for: anotherSelectedDevice.item.uniqueId))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 8)
                    }

                    if step.rawValue > Step.selectingSecondDevice.rawValue {
                        VStack(alignment: .leading, spacing: 8) {
                            if !canConfirmInheritance {
                                Text("invalid_inheritance")
                                    .fontWeight(.bold)
                            }
                            
                            Button("confirm_inheritance", action: confirmInheritance)
                            .buttonStyle(.borderedProminent)
                            .disabled(!canConfirmInheritance)
                        }
                    }
                }
            }

            Spacer()
            
            HStack {
                Button() {
                    tryingToDeleteAllInheritances = true
                    step = .beginning
                } label: {
                    Label("delete_all_inheritances", systemImage: "trash")
                }
                .disabled(tryingToDeleteAllInheritances)

                if tryingToDeleteAllInheritances {
                    Button() {
                        tryingToDeleteAllInheritances = false
                    } label: {
                        Image(systemName: "x.circle")
                    }

                    Button("confirm") { deleteAllInheritances() }
                        .buttonStyle(.borderedProminent)
                }
                
                Spacer()
                
                if (!tryingToDeleteAllInheritances) {
                    Button(action: { currentWindow = .settings }) {
                        Label("back", systemImage: "arrow.uturn.backward")
                    }
                }
            }
        }
        .padding(10)
        .frame(minWidth: 465, minHeight: 600)
    }
}
