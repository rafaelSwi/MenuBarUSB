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

    @CodableAppStorage(Key.renamedDevices) private var renamedDevices: [RenamedDevice] = []
    @CodableAppStorage(Key.inheritedDevices) private var inheritedDevices: [HeritageDevice] = []

    private func inheritanceStatus(for device: borrowing USBDevice) -> String {
        let inheritsFrom = inheritedDevices.contains { $0.deviceId == device.uniqueId }
        let hasHeirs = inheritedDevices.contains { $0.inheritsFrom == device.uniqueId }

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

    private func canConfirmInheritance(first: borrowing USBDevice, second: borrowing USBDevice) -> Bool {
        let masterId: String
        let heirId: String

        if role == .willGiveInheritance {
            masterId = first.uniqueId
            heirId = second.uniqueId
        } else {
            masterId = second.uniqueId
            heirId = first.uniqueId
        }

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

    private func deleteAllInheritances() {
        inheritedDevices.removeAll()
        tryingToDeleteAllInheritances = false
        selectedDevice = nil
        anotherSelectedDevice = nil
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

                        if tryingToDeleteAllInheritances {
                            Button("cancel") {
                                tryingToDeleteAllInheritances = false
                            }

                            Button("confirm") { deleteAllInheritances() }
                                .buttonStyle(.borderedProminent)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(localized: "select_device"))
                            .font(.headline)

                        Menu {
                            ForEach(manager.devices, id: \.self) { device in
                                Button(renamedDevices.first(where: { $0.deviceId == device.item.uniqueId })?.name ?? device.item.name) {
                                    selectedDevice = device
                                    step = .selectingRole
                                    role = .nothing
                                    anotherSelectedDevice = nil
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedDevice?.item.name ?? String(localized: "device"))
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 6).stroke(.gray))
                        }

                        if let selectedDevice {
                            Text(inheritanceStatus(for: selectedDevice.item))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
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
                                    Button(renamedDevices.first(where: { $0.deviceId == device.item.uniqueId })?.name ?? device.item.name) {
                                        anotherSelectedDevice = device
                                        step = .final
                                    }
                                }
                            } label: {
                                Text(anotherSelectedDevice?.item.name ?? String(localized: "device"))
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 6).stroke(.gray))
                            }

                            if let anotherSelectedDevice {
                                Text(inheritanceStatus(for: anotherSelectedDevice.item))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 8)
                    }

                    if step.rawValue > Step.selectingSecondDevice.rawValue {
                        VStack(alignment: .leading, spacing: 8) {
                            if !canConfirmInheritance(first: selectedDevice!.item, second: anotherSelectedDevice!.item) {
                                Text("invalid_inheritance")
                                    .fontWeight(.bold)
                            }

                            Button("confirm_inheritance") {
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

                                let hDevice = HeritageDevice(deviceId: uniqueIdHeir, inheritsFrom: uniqueIdMaster)
                                inheritedDevices.removeAll { $0.deviceId == uniqueIdHeir }
                                inheritedDevices.append(hDevice)

                                selectedDevice = nil
                                anotherSelectedDevice = nil
                                role = .nothing
                                step = .beginning
                            }
                            .disabled(!canConfirmInheritance(first: selectedDevice!.item, second: anotherSelectedDevice!.item))
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
