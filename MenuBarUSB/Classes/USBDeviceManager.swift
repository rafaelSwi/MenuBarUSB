import Foundation
import IOKit
import IOKit.network
import IOKit.ps
import IOKit.usb
import SwiftUI
import SystemConfiguration
import UserNotifications

final class USBDeviceManager: ObservableObject {
    @Published private(set) var devices: [USBDeviceWrapper] = []
    @Published var connectedCamouflagedDevices: Int = 0

    @Published var count: Int = 0
    @Published var chargeConnected: Bool = false
    @Published var chargePercentage: Int?
    @Published var ethernetCableConnected: Bool = false
    @Published var ethernetTraffic: Bool = false
    @Published var trafficCooldown: TimeInterval = 1.0
    @Published var lastTrafficDetected: Date = .distantPast
    @Published var trafficMonitorRunning: Bool = false

    private var powerSourceRunLoopSource: CFRunLoopSource?
    private var notifyPort: IONotificationPortRef?
    private var addedIterator: io_iterator_t = 0
    private var removedIterator: io_iterator_t = 0

    lazy var persistentEthernetStore: SCDynamicStore? = {
        var context = SCDynamicStoreContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        return SCDynamicStoreCreate(nil, "EthernetStatus" as CFString, nil, &context)
    }()

    @AS(Key.showNotifications) private var showNotifications = false
    @AS(Key.disableNotifCooldown) private var disableNotifCooldown = false
    @AS(Key.playHardwareSound) private var playHardwareSound: Bool = false
    @AS(Key.powerSourceInfo) private var powerSourceInfo: Bool = false
    @AS(Key.hardwareSound) private var hardwareSound: String = ""
    @AS(Key.showEthernet) var showEthernet = false
    @AS(Key.internetMonitoring) var internetMonitoring = false
    @AS(Key.storeDevices) private var storeDevices = false

    private var lastNotificationDate: Date = .distantPast
    private let notificationCooldown: TimeInterval = 3

    init() {
        if internetMonitoring, isEthernetConnected() {
            startEthernetMonitoring()
        }

        if powerSourceInfo {
            startPowerMonitoring()
        }

        startMonitoring()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refresh()
        }
    }

    deinit {
        stopMonitoring()
    }

    private func setCount() {
        var amount = devices.count
        if powerSourceInfo, chargeConnected {
            amount += 1
        }
        count = amount
    }

    private func canSendNotification() -> Bool {
        if disableNotifCooldown {
            return true
        }
        let now = Date()
        if now.timeIntervalSince(lastNotificationDate) < notificationCooldown {
            return false
        }
        lastNotificationDate = now
        return true
    }

    func refresh() {
        defer { setCount() }

        DispatchQueue.global(qos: .userInitiated).async(execute: DispatchWorkItem {
            let snapshot = self.fetchUSBDevices()

            var seenIds = Set<String>()
            var uniqueDevices: [USBDeviceWrapper] = []
            for device in snapshot {
                let id = device.item.uniqueId
                if !seenIds.contains(id) {
                    seenIds.insert(id)
                    uniqueDevices.append(device)
                }
            }

            let camouflagedIds = Set(CSM.Camouflaged.devices.map { $0.deviceId })
            var filteredDevices: [USBDeviceWrapper] = []
            var camouflagedCount = 0

            for device in uniqueDevices {
                let id = device.item.uniqueId
                if camouflagedIds.contains(id) {
                    camouflagedCount += 1
                } else {
                    filteredDevices.append(device)
                }
            }

            DispatchQueue.main.async(execute: DispatchWorkItem {
                self.devices = filteredDevices.sorted(by: {
                    ($0.item.vendor ?? "") < ($1.item.vendor ?? "") ||
                        ($0.item.vendor == $1.item.vendor && $0.item.name < $1.item.name)
                })

                self.connectedCamouflagedDevices = camouflagedCount
            })

            if self.powerSourceInfo {
                if self.isChargerConnected {
                    let value = self.getChargePercentage()
                    if self.chargePercentage != value {
                        DispatchQueue.main.async {
                            self.chargePercentage = value
                        }
                    }
                }
            }

            if self.showEthernet {
                let ethernetStatus = self.isEthernetConnected()
                DispatchQueue.main.async {
                    self.ethernetCableConnected = ethernetStatus
                }

                if !ethernetStatus {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
                        let retryStatus = self.isEthernetConnected()
                        DispatchQueue.main.async {
                            self.ethernetCableConnected = retryStatus
                        }
                    }
                }
            }
        })
    }

    func addDummy(amount: Int) {
        for i in Range(0 ... amount) {
            let newDevice = USBDevice(
                name: "Dummy (\(i))",
                vendor: "Dummy Vendor",
                vendorId: i,
                productId: i,
                serialNumber: "\(i)-DUMMY",
                locationId: UInt32(i),
                speedMbps: i,
                portMaxSpeedMbps: i,
                usbVersionBCD: i,
                isExternalStorage: false
            )
            let newDeviceWrapper = USBDeviceWrapper(newDevice)
            DispatchQueue.main.async(execute: DispatchWorkItem {
                self.devices.append(newDeviceWrapper)
            })
        }
    }

    private func isExternalStorageDevice(_ entry: io_registry_entry_t) -> Bool {
        return false // TODO: NOT WORKING

        var parent: io_registry_entry_t = 0
        var result = false

        var current = entry
        while IORegistryEntryGetParentEntry(current, kIOServicePlane, &parent) == KERN_SUCCESS {
            let classNameCString = UnsafeMutablePointer<CChar>.allocate(capacity: 128)
            defer { classNameCString.deallocate() }

            if IOObjectGetClass(parent, classNameCString) == KERN_SUCCESS {
                let className = String(cString: classNameCString)
                if className.contains("IOUSBMassStorageInterface") ||
                    className.contains("IOBlockStorageDevice") ||
                    className.contains("IOMedia")
                {
                    result = true
                    break
                }
            }

            current = parent
        }

        if parent != 0 { IOObjectRelease(parent) }
        return result
    }

    private func startPowerMonitoring() {
        let callback: IOPowerSourceCallbackType = { context in
            let mySelf = Unmanaged<USBDeviceManager>
                .fromOpaque(context!)
                .takeUnretainedValue()

            DispatchQueue.main.async {
                mySelf.updatePowerState()
            }
        }

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        if let source = IOPSNotificationCreateRunLoopSource(callback, refcon)?.takeRetainedValue() {
            powerSourceRunLoopSource = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        }

        DispatchQueue.main.async {
            self.updatePowerState()
        }
    }

    private func updatePowerState() {
        defer { setCount() }

        if !powerSourceInfo {
            chargePercentage = nil
            return
        }

        let charging = isChargerConnected
        let percentage = getChargePercentage()

        if chargeConnected != charging, showNotifications {
            if canSendNotification() {
                var battery = "\("battery".localized): \(chargePercentage ?? 0)%"
                if chargePercentage == nil {
                    battery = charging ? "charger_connected_body".localized : "charger_disconnected_body".localized
                }
                if charging {
                    Utils.System.sendNotification(
                        title: "charger_connected".localized,
                        body: battery
                    )
                } else {
                    Utils.System.sendNotification(
                        title: "charger_disconnected".localized,
                        body: "\("battery".localized): \(chargePercentage ?? 0)%"
                    )
                }
            }
        }

        chargeConnected = charging

        if charging {
            chargePercentage = percentage
        } else {
            chargePercentage = nil
        }
    }

    private var isChargerConnected: Bool {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef]
        else { return false }

        for ps in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, ps)?
                .takeUnretainedValue() as? [String: Any] else { continue }

            if let state = description[kIOPSPowerSourceStateKey as String] as? String {
                if state == kIOPSACPowerValue {
                    return true
                }
            }

            if let external = description["ExternalConnected"] as? Bool {
                if external { return true }
            }
        }

        return false
    }

    private func getChargePercentage() -> Int? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef]
        else { return nil }

        for ps in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, ps)?
                .takeUnretainedValue() as? [String: Any] else { continue }

            if let type = description[kIOPSTypeKey as String] as? String,
               type == kIOPSInternalBatteryType as String,
               let current = description[kIOPSCurrentCapacityKey as String] as? Int,
               let max = description[kIOPSMaxCapacityKey as String] as? Int
            {
                return Int((Double(current) / Double(max)) * 100)
            }
        }

        return nil
    }

    private func fetchUSBDevices() -> [USBDeviceWrapper] {
        var result: [USBDeviceWrapper] = []
        var seenDeviceIds = Set<String>()

        func addUniqueDevices(from name: String) {
            let devices = fetchMatchingDevices(name: name)
            for device in devices {
                let deviceId = device.item.uniqueId
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

    private func fetchMatchingDevices(name: String) -> [USBDeviceWrapper] {
        var result: [USBDeviceWrapper] = []
        let matching = IOServiceMatching(name)

        var iterator: io_iterator_t = 0
        let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        guard kr == KERN_SUCCESS else { return [] }
        defer { IOObjectRelease(iterator) }

        while case let entry = IOIteratorNext(iterator), entry != 0 {
            if let dev = makeDevice(from: entry) {
                if storeDevices {
                    CSM.Stored.add(dev)
                }
                result.append(dev)
            }
            IOObjectRelease(entry)
        }
        return result
    }

    private func makeDevice(from entry: io_registry_entry_t) -> USBDeviceWrapper? {
        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(entry, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any] else { return nil }

        func num(_ key: String) -> NSNumber? { dict[key] as? NSNumber }
        func intValue(_ key: String) -> Int? { num(key)?.intValue }
        func uint32Value(_ key: String) -> UInt32? { num(key)?.uint32Value }
        func doubleValue(_ key: String) -> Double? { num(key)?.doubleValue }
        func stringValue(_ key: String) -> String? { dict[key] as? String }

        let vendorId = intValue(kUSBVendorID as String) ?? 0
        let productId = intValue(kUSBProductID as String) ?? 0
        let registryName = tryGetIORegistryName(entry) ?? "USB Device"
        let productString = stringValue(kUSBProductString as String)
        let vendorString = stringValue(kUSBVendorString as String)
        let serial = stringValue(kUSBSerialNumberString as String)
        let locationId = uint32Value(kUSBDevicePropertyLocationID as String)

        let linkSpeedBpsCandidates = [
            "kUSBDevicePropertyLinkSpeed", "LinkSpeed", "DeviceLinkSpeed", "link-speed",
        ]
        let linkSpeedBps: Double? = linkSpeedBpsCandidates
            .compactMap { doubleValue($0) ?? intValue($0).map(Double.init) }
            .first
        let linkSpeedMbpsFromDevice = linkSpeedBps.map { Int($0 / 1_000_000.0) }

        let speedCode = intValue(kUSBDevicePropertySpeed as String)
        let speedMbpsFromCode: Int? = speedCode.flatMap {
            switch $0 {
            case 0: return 2
            case 1: return 12
            case 2: return 480
            case 3: return 5000
            case 4: return 10000
            default: return nil
            }
        }

        func parentPortMaxMbps(_ entry: io_registry_entry_t) -> Int? {
            var parent: io_registry_entry_t = 0
            guard IORegistryEntryGetParentEntry(entry, kIOServicePlane, &parent) == KERN_SUCCESS else { return nil }
            defer { IOObjectRelease(parent) }

            var pprops: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(parent, &pprops, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                  let pdict = pprops?.takeRetainedValue() as? [String: Any] else { return nil }

            func pnum(_ k: String) -> NSNumber? { pdict[k] as? NSNumber }
            func pint(_ k: String) -> Int? { pnum(k)?.intValue }
            func pdouble(_ k: String) -> Double? { pnum(k)?.doubleValue }

            let candidates = [
                "kUSBHostPortPropertyLinkSpeed", "PortLinkSpeed", "PortSpeed",
                "LinkSpeed", "MaxLinkRate", "maxLinkSpeed",
            ]
            if let bps = candidates.compactMap({ pdouble($0) ?? pint($0).map(Double.init) }).first {
                return Int(bps / 1_000_000.0)
            }

            if let portType = pdict["PortType"] as? String {
                if portType.localizedCaseInsensitiveContains("SuperSpeedPlus") { return 10000 }
                if portType.localizedCaseInsensitiveContains("SuperSpeed") { return 5000 }
            }
            return nil
        }

        let portMaxSpeedMbps = parentPortMaxMbps(entry)
        let bcdUSBCandidates = ["bcdUSB", "kUSBDevicePropertyUSBReleaseNumber", "USB-bcdUSB"]
        let usbVersionBCD = bcdUSBCandidates.compactMap { intValue($0) }.first
        let speedMbps = linkSpeedMbpsFromDevice ?? speedMbpsFromCode

        let wrapper = USBDeviceWrapper(USBDevice(
            name: productString ?? registryName,
            vendor: vendorString,
            vendorId: vendorId,
            productId: productId,
            serialNumber: serial,
            locationId: locationId,
            speedMbps: speedMbps,
            portMaxSpeedMbps: portMaxSpeedMbps,
            usbVersionBCD: usbVersionBCD,
            isExternalStorage: isExternalStorageDevice(entry)
        ))

        return wrapper
    }

    private func tryGetIORegistryName(_ entry: io_registry_entry_t) -> String? {
        var cName = [CChar](repeating: 0, count: 128)
        let res = IORegistryEntryGetName(entry, &cName)
        if res == KERN_SUCCESS {
            return String(cString: cName)
        }
        return nil
    }

    private func startMonitoring() {
        defer { refresh() }

        notifyPort = IONotificationPortCreate(kIOMainPortDefault)
        guard let notifyPort else { return }

        if let runloopSource = IONotificationPortGetRunLoopSource(notifyPort)?.takeUnretainedValue() {
            CFRunLoopAddSource(CFRunLoopGetMain(), runloopSource, .defaultMode)
        }

        let matchAdded = IOServiceMatching(kIOUSBDeviceClassName)
        let matchRemoved = IOServiceMatching(kIOUSBDeviceClassName)

        let addedCallback: IOServiceMatchingCallback = { refcon, iterator in
            let mySelf = Unmanaged<USBDeviceManager>.fromOpaque(refcon!).takeUnretainedValue()

            var deviceNames: [String] = []
            var service: io_object_t
            repeat {
                service = IOIteratorNext(iterator)
                if service != 0 {
                    var parts: [String] = []

                    if let vendor = IORegistryEntryCreateCFProperty(
                        service,
                        kUSBVendorString as CFString,
                        kCFAllocatorDefault,
                        0
                    )?.takeUnretainedValue() as? String {
                        parts.append(vendor)
                    }

                    if let product = IORegistryEntryCreateCFProperty(
                        service,
                        kUSBProductString as CFString,
                        kCFAllocatorDefault,
                        0
                    )?.takeUnretainedValue() as? String {
                        parts.append(product)
                    }

                    if !parts.isEmpty {
                        deviceNames.append(parts.joined(separator: " "))
                    }

                    IOObjectRelease(service)
                }
            } while service != 0

            DispatchQueue.main.async {
                mySelf.refresh()
                if mySelf.playHardwareSound {
                    Utils.System.playSound(HardwareSound[mySelf.hardwareSound]?.connect)
                }
                if mySelf.showNotifications, mySelf.canSendNotification() {
                    let deviceList = deviceNames.isEmpty ? "" : "\(deviceNames.joined(separator: ", ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))"
                    if deviceList == "" {
                        Utils.System.sendNotification(
                            title: "usb_detected".localized,
                            body: "usb_detected_info".localized
                        )

                    } else {
                        Utils.System.sendNotification(
                            title: "usb_detected".localized,
                            body: String(format: "device_connected".localized, deviceList)
                        )
                    }
                }
            }
        }

        let removedCallback: IOServiceMatchingCallback = { refcon, iterator in
            let mySelf = Unmanaged<USBDeviceManager>.fromOpaque(refcon!).takeUnretainedValue()

            var deviceNames: [String] = []
            var service: io_object_t
            repeat {
                service = IOIteratorNext(iterator)
                if service != 0 {
                    if let vendor = IORegistryEntryCreateCFProperty(service, kUSBVendorString as CFString, kCFAllocatorDefault, 0)?
                        .takeUnretainedValue() as? String,
                        let product = IORegistryEntryCreateCFProperty(service, kUSBProductString as CFString, kCFAllocatorDefault, 0)?
                        .takeUnretainedValue() as? String
                    {
                        deviceNames.append("\(vendor) \(product)")
                    }
                    IOObjectRelease(service)
                }
            } while service != 0

            DispatchQueue.main.async {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    mySelf.refresh()
                }

                if mySelf.playHardwareSound {
                    var playDefault: Bool = true
                    if let uniqueId = mySelf.makeDevice(from: service)?.item.uniqueId {
                        if let soundDevice = CSM.SoundDevices[uniqueId] {
                            playDefault = false
                            Utils.System.playSound(HardwareSound[soundDevice.soundId]?.disconnect)
                        }
                    }
                    if playDefault {
                        Utils.System.playSound(HardwareSound[mySelf.hardwareSound]?.disconnect)
                    }
                }

                if mySelf.showNotifications, mySelf.canSendNotification() {
                    let deviceList = deviceNames.joined(separator: ", ")
                    Utils.System.sendNotification(
                        title: "usb_disconnected".localized,
                        body: deviceList.isEmpty
                            ? "usb_disconnected_info".localized
                            : String(format: "device_disconnected".localized, deviceList)
                    )
                }
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
        if kr1 == KERN_SUCCESS { while IOIteratorNext(addedIterator) != 0 {} }

        let kr2 = IOServiceAddMatchingNotification(
            notifyPort,
            kIOTerminatedNotification,
            matchRemoved,
            removedCallback,
            refcon,
            &removedIterator
        )
        if kr2 == KERN_SUCCESS { while IOIteratorNext(removedIterator) != 0 {} }
    }

    private func stopMonitoring() {
        if let source = powerSourceRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
        }
        powerSourceRunLoopSource = nil

        if addedIterator != 0 { IOObjectRelease(addedIterator); addedIterator = 0 }
        if removedIterator != 0 { IOObjectRelease(removedIterator); removedIterator = 0 }
        if let notifyPort {
            if let runloopSource = IONotificationPortGetRunLoopSource(notifyPort)?.takeUnretainedValue() {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), runloopSource, .defaultMode)
            }
            IONotificationPortDestroy(notifyPort)
            self.notifyPort = nil
        }
    }
}
