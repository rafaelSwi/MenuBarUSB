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
    
    @Binding var currentWindow: AppWindow
    
    @State private var selectedDevice: USBDevice?
    @State private var anotherSelectedDevice: USBDevice?
    
    @CodableAppStorage(StorageKeys.renamedDevices) private var renamedDevices: [RenamedDevice] = []
    
    var body: some View {
        
        VStack {
            ScrollView {
                
                Menu {
                    ForEach(manager.devices) { device in
                        Button(renamedDevices.first(where: { $0.deviceId == USBDevice.uniqueId(device) })?.name ?? device.name) {
                            selectedDevice = device
                            step = .selectingRole
                        }
                    }
                } label: {
                    Text(selectedDevice?.name ?? String(localized: "device"))
                }
                
                if (step.rawValue > Step.beginning.rawValue) {
                    Text(String(localized: "this_device"))
                    HStack {
                        Image(systemName: (role == .willGiveInheritance) ? "checkmark" : "circle")
                        Button(String(localized: "will_be_the_master")) {
                            role = .willGiveInheritance
                            step = .selectingSecondDevice
                            anotherSelectedDevice = nil
                        }
                    }
                    
                    HStack {
                        Image(systemName: (role == .willReceiveInheritance) ? "checkmark" : "circle")
                        Button(String(localized: "is_inheriting_from_some_device")) {
                            role = .willReceiveInheritance
                            step = .selectingSecondDevice
                            anotherSelectedDevice = nil
                        }
                    }
                    
                }
                
                if (step.rawValue > Step.selectingRole.rawValue) {
                    let text = String(localized: (role == .willGiveInheritance) ? "which_one_will_be_the_heir" : "which_device_is_it_inheriting_from")
                    Text(text)
                    Menu {
                        ForEach(manager.devices) { device in
                            Button(renamedDevices.first(where: { $0.deviceId == USBDevice.uniqueId(device) })?.name ?? device.name) {
                                anotherSelectedDevice = device
                                step = .final
                            }
                        }
                    } label: {
                        Text(anotherSelectedDevice?.name ?? String(localized: "device"))
                    }
                }
                
                if (step.rawValue > Step.selectingSecondDevice.rawValue) {
                    
                    if (selectedDevice == anotherSelectedDevice) {
                        Text(String(localized: "device_cannot_inherit_or_be_inherited_by_itself"))
                    }
                    
                }
                
                
                
                
                
                
                
            }
            Button(action: {currentWindow = .settings}) {
                Label(String(localized: "back"), systemImage: "arrow.uturn.backward")
            }
        }
        .padding(10)
        .frame(minWidth: 465, minHeight: 530)
        
    }
}
