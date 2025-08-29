//
//  USBDeviceManager.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import Foundation
import IOKit
import IOKit.usb

final class USBDeviceManager: ObservableObject {
    @Published private(set) var devices: [USBDevice] = []
    
    private var notifyPort: IONotificationPortRef?
    private var addedIterator: io_iterator_t = 0
    private var removedIterator: io_iterator_t = 0
    
    init() {
        startMonitoring()
        refresh()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // Public
    
    func refresh() {
        DispatchQueue.global(qos: .userInitiated).async {
            let snapshot = self.fetchUSBDevices()
            
            let uniqueDevices = Set(snapshot)
            
            DispatchQueue.main.async {
                self.devices = uniqueDevices.sorted(by: {
                    ($0.vendor ?? "") < ($1.vendor ?? "")
                    || ($0.vendor == $1.vendor && $0.name < $1.name)
                })
            }
        }
    }
    
    // USB Query
    
    private func fetchUSBDevices() -> [USBDevice] {
        var result: [USBDevice] = []
        var seenDeviceIds = Set<String>()

        func addUniqueDevices(from name: String) {
            let devices = fetchMatchingDevices(name: name)
            for device in devices {
                let deviceId = "\(device.vendorId)-\(device.productId)-\(String(describing: device.locationId))"
                
                if !seenDeviceIds.contains(deviceId) {
                    result.append(device)
                    seenDeviceIds.insert(deviceId)
                }
            }
        }
        
        addUniqueDevices(from: "IOUSBHostDevice")
        
        addUniqueDevices(from: kIOUSBDeviceClassName)

        return result
    }

    private func fetchMatchingDevices(name: String) -> [USBDevice] {
        var result: [USBDevice] = []
        let matching = IOServiceMatching(name)
        
        var iterator: io_iterator_t = 0
        let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        guard kr == KERN_SUCCESS else { return [] }
        defer { IOObjectRelease(iterator) }
        
        while case let entry = IOIteratorNext(iterator), entry != 0 {
            if let dev = makeDevice(from: entry) {
                
                result.append(dev)
            }
            IOObjectRelease(entry)
        }
        return result
    }
    
    private func makeDevice(from entry: io_registry_entry_t) -> USBDevice? {
        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(entry, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any] else {
            return nil
        }
        
        func intValue(_ key: String) -> Int? {
            (dict[key] as? NSNumber)?.intValue
        }
        func uint32Value(_ key: String) -> UInt32? {
            (dict[key] as? NSNumber)?.uint32Value
        }
        func stringValue(_ key: String) -> String? {
            dict[key] as? String
        }
        
        let vendorId = intValue(kUSBVendorID as String) ?? 0
        let productId = intValue(kUSBProductID as String) ?? 0
        
        let registryName = tryGetIORegistryName(entry) ?? "USB Device"
        let productString = stringValue(kUSBProductString as String)
        let vendorString = stringValue(kUSBVendorString as String)
        let serial = stringValue(kUSBSerialNumberString as String)
        let locationId = uint32Value(kUSBDevicePropertyLocationID as String)
        let speedBps = intValue(kUSBDevicePropertySpeed as String)
        let speedCode = intValue(kUSBDevicePropertySpeed as String)
        let speedMbps: Int? = speedCode.flatMap { code in
            switch code {
            case 0: return 2        // 1.5 Mbps ~ arredondado para 2
            case 1: return 12       // Full-Speed
            case 2: return 480      // High-Speed
            case 3: return 5000     // SuperSpeed
            case 4: return 10000    // SuperSpeed+
            default: return nil
            }
        }
        
        return USBDevice(
            name: productString ?? registryName,
            vendor: vendorString,
            vendorId: vendorId,
            productId: productId,
            serialNumber: serial,
            locationId: locationId,
            speedMbps: speedMbps
        )
    }
    
    private func tryGetIORegistryName(_ entry: io_registry_entry_t) -> String? {
        var cName = [CChar](repeating: 0, count: 128)
        let res = IORegistryEntryGetName(entry, &cName)
        if res == KERN_SUCCESS {
            return String(cString: cName)
        }
        return nil
    }
    
    // Hotplug Monitoring
    
    private func startMonitoring() {
        notifyPort = IONotificationPortCreate(kIOMainPortDefault)
        guard let notifyPort else { return }
        
        if let runloopSource = IONotificationPortGetRunLoopSource(notifyPort)?.takeUnretainedValue() {
            CFRunLoopAddSource(CFRunLoopGetMain(), runloopSource, .defaultMode)
        }
        
        let matchAdded = IOServiceMatching(kIOUSBDeviceClassName)
        let matchRemoved = IOServiceMatching(kIOUSBDeviceClassName)
        
        let addedCallback: IOServiceMatchingCallback = { (refcon, iterator) in
            let _ = iterator
            let mySelf = Unmanaged<USBDeviceManager>.fromOpaque(refcon!).takeUnretainedValue()
            while IOIteratorNext(iterator) != 0 {}
            DispatchQueue.main.async {
                mySelf.refresh()
            }
        }
        
        let removedCallback: IOServiceMatchingCallback = { (refcon, iterator) in
            let _ = iterator
            let mySelf = Unmanaged<USBDeviceManager>.fromOpaque(refcon!).takeUnretainedValue()
            while IOIteratorNext(iterator) != 0 {}
            DispatchQueue.main.async {
                mySelf.refresh()
            }
        }
        
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        
        let kr1 = IOServiceAddMatchingNotification(
            notifyPort,
            kIOMatchedNotification,
            matchAdded,
            addedCallback,
            refcon,
            &addedIterator
        )
        if kr1 == KERN_SUCCESS {
            while IOIteratorNext(addedIterator) != 0 {}
        }
        
        let kr2 = IOServiceAddMatchingNotification(
            notifyPort,
            kIOTerminatedNotification,
            matchRemoved,
            removedCallback,
            refcon,
            &removedIterator
        )
        if kr2 == KERN_SUCCESS {
            while IOIteratorNext(removedIterator) != 0 {}
        }
    }
    
    private func stopMonitoring() {
        if addedIterator != 0 {
            IOObjectRelease(addedIterator)
            addedIterator = 0
        }
        if removedIterator != 0 {
            IOObjectRelease(removedIterator)
            removedIterator = 0
        }
        if let notifyPort {
            if let runloopSource = IONotificationPortGetRunLoopSource(notifyPort)?.takeUnretainedValue() {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), runloopSource, .defaultMode)
            }
            IONotificationPortDestroy(notifyPort)
            self.notifyPort = nil
        }
    }
}
