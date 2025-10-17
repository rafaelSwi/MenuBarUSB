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
            let filtered = items.filter { device in
                let notContain = !connectedDevices.contains { $0.item.uniqueId == device.deviceId }
                let isHidden = CodableStorageManager.Camouflaged.devices.contains { $0.deviceId == device.deviceId }
                return notContain && !isHidden
            }.map { device in
                if let renamed = CodableStorageManager.Renamed.devices.first(where: { $0.deviceId == device.deviceId }) {
                    var newDevice = device
                    newDevice.name = renamed.name
                    return newDevice
                }
                return device
            }

            var seenIds = Set<String>()
            let uniqueDevices = filtered.filter { device in
                if seenIds.contains(device.deviceId) {
                    return false
                } else {
                    seenIds.insert(device.deviceId)
                    return true
                }
            }

            return uniqueDevices
        }
        
        static func add(_ d: USBDeviceWrapper) {
            items.removeAll { $0.deviceId == d.item.uniqueId }
            items.append(StoredDevice(deviceId: d.item.uniqueId, name: d.item.name))
        }
        
        static func get(withId id: String?) -> StoredDevice? {
            return items.first(where: { $0.deviceId == id })
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
        
        static func add(_ deviceId: String?, _ name: String) {
            if (deviceId == nil) { return }
            items.removeAll { $0.deviceId == deviceId }
            items.append(RenamedDevice(deviceId: deviceId!, name: name))
        }
        
        static func get(withId id: String?) -> RenamedDevice? {
            return items.first(where: { $0.deviceId == id })
        }
        
        static func getName(withId id: String?, placeholder: String) -> String {
            let item = items.first(where: { $0.deviceId == id })
            if (item == nil) { return placeholder }
            return item?.name ?? placeholder
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
    
    final class Heritage {
        
        @CodableAppStorage(Key.inheritedDevices)
        static var items: [HeritageDevice] = []
        
        static var devices: [HeritageDevice] {
            return items
        }
        
        static func add(withId id: String?, inheritsFrom: String?) {
            if (id == nil || inheritsFrom == nil) { return }
            items.removeAll { $0.deviceId == id }
            items.append(HeritageDevice(deviceId: id!, inheritsFrom: inheritsFrom!))
        }
        
        static func get(withId id: String?) -> HeritageDevice? {
            items.first(where: { $0.deviceId == id })
        }
        
        static func remove(withId id: String) {
            items.removeAll { $0.deviceId == id }

            let directChildren = items
                .filter { $0.inheritsFrom == id }
                .map { $0.deviceId }

            for childId in directChildren {
                CodableStorageManager.Heritage.remove(withId: childId)
            }

            items.removeAll { $0.inheritsFrom == id }
        }
        
        static func clear() {
            items.removeAll(keepingCapacity: false)
        }
        
    }
    
    
    
}
