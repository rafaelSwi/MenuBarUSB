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
    
    @State private var selectedDevice: USBDevice?
    @State private var anotherSelectedDevice: USBDevice?
    
    @CodableAppStorage(StorageKeys.renamedDevices) private var renamedDevices: [RenamedDevice] = []
    @CodableAppStorage(StorageKeys.inheritedDevices) private var inheritedDevices: [HeritageDevice] = []
    
    func inheritanceStatus(for device: USBDevice) -> String {
        let id = USBDevice.uniqueId(device)
        let inheritsFrom = inheritedDevices.contains { $0.deviceId == id }
        let hasHeirs = inheritedDevices.contains { $0.inheritsFrom == id }
        
        if inheritsFrom && hasHeirs {
            return String(localized: "both_inheriting_and_being_inherited")
        } else if inheritsFrom {
            return String(localized: "inheriting_from_another")
        } else if hasHeirs {
            return String(localized: "passing_inheritance_to_others")
        } else {
            return String(localized: "this_device_has_no_inheritance_ties")
        }
    }
    
    func canConfirmInheritance(master: USBDevice, heir: USBDevice) -> Bool {
        let masterId = USBDevice.uniqueId(master)
        let heirId = USBDevice.uniqueId(heir)
        
        if masterId == heirId { return false }
        
        if let parent = inheritedDevices.first(where: { $0.deviceId == masterId })?.inheritsFrom,
           parent == heirId { return false }
        
        var currentId = masterId
        while let parent = inheritedDevices.first(where: { $0.deviceId == currentId })?.inheritsFrom {
            if parent == heirId { return false }
            currentId = parent
        }
        
        return true
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    
                    HStack {
                        
                        Button("delete_all_inheritances") {
                            tryingToDeleteAllInheritances = true
                            step = .beginning
                        }
                        .disabled(tryingToDeleteAllInheritances)
                        
                        if (tryingToDeleteAllInheritances) {
                            
                            Button("cancel") {
                                tryingToDeleteAllInheritances = false
                            }
                            
                            Button("confirm") {
                                inheritedDevices.removeAll()
                                tryingToDeleteAllInheritances = false
                                selectedDevice = nil
                                anotherSelectedDevice = nil
                            }
                            .buttonStyle(.borderedProminent)
                            
                        }
                        
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(localized: "select_device"))
                            .font(.headline)
                        
                        Menu {
                            ForEach(manager.devices) { device in
                                Button(renamedDevices.first(where: { $0.deviceId == USBDevice.uniqueId(device) })?.name ?? device.name) {
                                    selectedDevice = device
                                    step = .selectingRole
                                    role = .nothing
                                    anotherSelectedDevice = nil
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedDevice?.name ?? String(localized: "device"))
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 6).stroke(.gray))
                        }
                        
                        if let selectedDevice {
                            Text(inheritanceStatus(for: selectedDevice))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if step.rawValue > Step.beginning.rawValue, let selectedDevice {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("this_device")
                                .font(.headline)
                            
                            HStack {
                                Image(systemName: (role == .willGiveInheritance) ? "checkmark.circle.fill" : "circle")
                                Button("will_be_the_master") {
                                    role = .willGiveInheritance
                                    step = .selectingSecondDevice
                                    anotherSelectedDevice = nil
                                }
                            }
                            
                            HStack {
                                Image(systemName: (role == .willReceiveInheritance) ? "checkmark.circle.fill" : "circle")
                                Button("is_inheriting_from_some_device") {
                                    role = .willReceiveInheritance
                                    step = .selectingSecondDevice
                                    anotherSelectedDevice = nil
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    if step.rawValue > Step.selectingRole.rawValue, let selectedDevice {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(role == .willGiveInheritance ? "which_one_will_be_the_heir" : "which_device_is_it_inheriting_from")
                                .font(.headline)
                            
                            Menu {
                                ForEach(manager.devices) { device in
                                    Button(renamedDevices.first(where: { $0.deviceId == USBDevice.uniqueId(device) })?.name ?? device.name) {
                                        anotherSelectedDevice = device
                                        step = .final
                                    }
                                }
                            } label: {
                                Text(anotherSelectedDevice?.name ?? String(localized: "device"))
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 6).stroke(.gray))
                            }
                            
                            if let anotherSelectedDevice {
                                Text(inheritanceStatus(for: anotherSelectedDevice))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    if step.rawValue > Step.selectingSecondDevice.rawValue {
                        VStack(alignment: .leading, spacing: 8) {
                            if !canConfirmInheritance(
                                master: role == .willGiveInheritance ? selectedDevice! : anotherSelectedDevice!,
                                heir: role == .willGiveInheritance ? anotherSelectedDevice! : selectedDevice!
                            ) {
                                Text("invalid_inheritance")
                                    .fontWeight(.bold)
                            }
                            
                            Button("confirm_inheritance") {
                                var uniqueIdMaster: String
                                var uniqueIdHeir: String
                                
                                switch role {
                                case .nothing: return
                                case .willGiveInheritance:
                                    uniqueIdMaster = USBDevice.uniqueId(selectedDevice!)
                                    uniqueIdHeir = USBDevice.uniqueId(anotherSelectedDevice!)
                                case .willReceiveInheritance:
                                    uniqueIdMaster = USBDevice.uniqueId(anotherSelectedDevice!)
                                    uniqueIdHeir = USBDevice.uniqueId(selectedDevice!)
                                }
                                
                                let hDevice = HeritageDevice(deviceId: uniqueIdHeir, inheritsFrom: uniqueIdMaster)
                                inheritedDevices.removeAll { $0.deviceId == uniqueIdHeir }
                                inheritedDevices.append(hDevice)
                                
                                selectedDevice = nil
                                anotherSelectedDevice = nil
                                role = .nothing
                                step = .beginning
                            }
                            .disabled(
                                !canConfirmInheritance(
                                    master: role == .willGiveInheritance ? selectedDevice! : anotherSelectedDevice!,
                                    heir: role == .willGiveInheritance ? anotherSelectedDevice! : selectedDevice!
                                ))
                        }
                    }
                    
                    
                }
            }
            
            Spacer()
            
            HStack {
                
                Spacer()
                
                Button(action: { currentWindow = .settings }) {
                    Label("back", systemImage: "arrow.uturn.backward")
                }
                
            }
            
        }
        .padding(10)
        .frame(minWidth: 465, minHeight: 600)
    }
    
}
