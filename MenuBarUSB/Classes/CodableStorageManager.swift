//
//  StoredDeviceManager.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth Swierczynski on 11/10/25.
//

import Foundation

final class CodableStorageManager {
    
    final class Stored {
        
        @CodableAppStorage(Key.storedDevices)
        static var items: [StoredDevice] = []
        
        static var devices: [StoredDevice] {
            return items
        }
        
        static func filteredDevices(_ connectedDevices: [USBDeviceWrapper]) -> [StoredDevice] {
            return items.filter { device in
                let notContain = !connectedDevices.contains { $0.item.uniqueId == device.deviceId }
                let isHidden = CodableStorageManager.Camouflaged.devices.contains { $0.deviceId == device.deviceId }
                return (notContain && !isHidden)
            }.map { device in
                let renamed: RenamedDevice? = CodableStorageManager.Renamed.devices.first { $0.deviceId == device.deviceId }
                if (renamed != nil) {
                    var newDevice = device
                    newDevice.name = renamed!.name
                    return newDevice
                }
                return device
            }
        }
        
        static func add(_ d: USBDeviceWrapper) {
            items.removeAll { $0.deviceId == d.item.uniqueId }
            items.append(StoredDevice(deviceId: d.item.uniqueId, name: d.item.name))
        }
        
        static func remove(withId id: String) {
            items.removeAll { $0.deviceId == id }
        }
        
        static func clear() {
            items.removeAll(keepingCapacity: false)
        }
    }
    
    final class Renamed {
        
        @CodableAppStorage(Key.renamedDevices)
        static var items: [RenamedDevice] = []
        
        static var devices: [RenamedDevice] {
            return items
        }
        
        static func add(_ d: USBDeviceWrapper?, _ name: String) {
            if (d == nil) { return }
            items.removeAll { $0.deviceId == d!.item.uniqueId }
            items.append(RenamedDevice(deviceId: d!.item.uniqueId, name: name))
        }
        
        static func remove(withId id: String) {
            items.removeAll { $0.deviceId == id }
        }
        
        static func clear() {
            items.removeAll(keepingCapacity: false)
        }
        
    }
    
    final class Camouflaged {
        
        @CodableAppStorage(Key.camouflagedDevices)
        static var items: [CamouflagedDevice] = []
        
        static var devices: [CamouflagedDevice] {
            return items
        }
        
        static func add(withId id: String?) {
            if (id == nil) { return }
            items.removeAll { $0.deviceId == id }
            items.append(CamouflagedDevice(deviceId: id!))
        }
        
        static func remove(withId id: String) {
            items.removeAll { $0.deviceId == id }
        }
        
        static func clear() {
            items.removeAll(keepingCapacity: false)
        }
        
    }
    
    
    
}
