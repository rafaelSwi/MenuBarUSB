//
//  USBDeviceManager+Ethernet.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth Swierczynski on 08/10/25.
//

import Foundation
import ObjectiveC.runtime
import SwiftUI
import SystemConfiguration

extension USBDeviceManager {
    private enum AssociatedKeys {
        static var ethernetTimer = "USBDeviceManagerEthernetTimer"
        static var previousTraffic = "USBDeviceManagerPreviousTraffic"
    }

    var ethernetTimer: Timer? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.ethernetTimer) as? Timer }
        set { objc_setAssociatedObject(self, &AssociatedKeys.ethernetTimer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private var previousTraffic: [String: (ibytes: UInt64, obytes: UInt64)] {
        get { objc_getAssociatedObject(self, &AssociatedKeys.previousTraffic) as? [String: (ibytes: UInt64, obytes: UInt64)] ?? [:] }
        set { objc_setAssociatedObject(self, &AssociatedKeys.previousTraffic, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func startEthernetMonitoring() {
        guard showEthernet else { return }

        print("Starting Ethernet Monitoring...")
        print("Detected interfaces: \(monitoredEthernetInterfaces)")

        if !ethernetCableConnected { return }

        startMonitoringEthernet()

        stopEthernetMonitoring()

        @AS(Key.fastMonitor) var fastMonitor = false
        ethernetTimer = Timer.scheduledTimer(withTimeInterval: fastMonitor ? 0.4 : 2.1, repeats: true) { [weak self] _ in
            guard let self else { return }

            let connected = self.isEthernetConnected()
            if self.ethernetCableConnected != connected {
                self.ethernetCableConnected = connected
                print("Ethernet status changed: \(connected)")
            }

            if connected {
                self.updateEthernetTraffic()
            }
        }
    }

    func stopEthernetMonitoring() {
        ethernetTimer?.invalidate()
        ethernetTimer = nil
        ethernetTraffic = false
        trafficMonitorRunning = false
    }

    func isEthernetConnected() -> Bool {
        guard let store = persistentEthernetStore else { return false }
        for interface in monitoredEthernetInterfaces {
            let key = "State:/Network/Interface/\(interface)/Link" as CFString
            if let value = SCDynamicStoreCopyValue(store, key) as? [String: Any],
               let active = value["Active"] as? Bool,
               active
            {
                return true
            }
        }
        return false
    }

    private func updateEthernetTraffic() {
        trafficMonitorRunning = true

        if isEthernetConnected() == false {
            trafficMonitorRunning = false
            return
        }

        var trafficDetected = false
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddrPtr) == 0, let firstAddr = ifaddrPtr else { return }
        defer { freeifaddrs(ifaddrPtr) }

        var ptr = firstAddr
        while ptr.pointee.ifa_next != nil {
            let name = String(cString: ptr.pointee.ifa_name)
            if monitoredEthernetInterfaces.contains(name),
               let data = ptr.pointee.ifa_data?.assumingMemoryBound(to: if_data.self).pointee
            {
                let currentIn = UInt64(data.ifi_ibytes)
                let currentOut = UInt64(data.ifi_obytes)

                let previous = previousTraffic[name] ?? (ibytes: 0, obytes: 0)
                let deltaIn: UInt64
                if currentIn >= previous.ibytes {
                    deltaIn = currentIn - previous.ibytes
                } else {
                    deltaIn = currentIn
                }

                let deltaOut: UInt64
                if currentOut >= previous.obytes {
                    deltaOut = currentOut - previous.obytes
                } else {
                    deltaOut = currentOut
                }

                previousTraffic[name] = (ibytes: currentIn, obytes: currentOut)

                if deltaIn > 0 || deltaOut > 0 {
                    trafficDetected = true
                    lastTrafficDetected = Date()
                }

                print("Interface: \(name)")
                print("Received: \(currentIn) bytes, Sent: \(currentOut) bytes")
                print("Delta In: \(deltaIn), Delta Out: \(deltaOut)")
            }
            ptr = ptr.pointee.ifa_next!
        }

        if !trafficDetected, Date().timeIntervalSince(lastTrafficDetected) > trafficCooldown {
            trafficDetected = false
        } else if trafficDetected {
            lastTrafficDetected = Date()
        }

        DispatchQueue.main.async {
            self.ethernetTraffic = trafficDetected
            print("ethernetTraffic updated: \(trafficDetected)")
        }
    }

    private var monitoredEthernetInterfaces: [String] {
        guard let interfaces = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] else { return [] }
        return interfaces.compactMap { interface in
            if SCNetworkInterfaceGetInterfaceType(interface) as String? == kSCNetworkInterfaceTypeEthernet as String {
                return SCNetworkInterfaceGetBSDName(interface) as String?
            }
            return nil
        }
    }

    private func startMonitoringEthernet() {
        func ethernetCallback(store _: SCDynamicStore, changedKeys _: CFArray, info: UnsafeMutableRawPointer?) {
            guard let info else { return }
            let manager = Unmanaged<USBDeviceManager>.fromOpaque(info).takeUnretainedValue()
            DispatchQueue.main.async {
                manager.ethernetCableConnected = manager.isEthernetConnected()
            }
        }

        var context = SCDynamicStoreContext(
            version: 0,
            info: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        guard let store = SCDynamicStoreCreate(nil, "EthernetMonitor" as CFString, ethernetCallback, &context) else { return }

        let keys = monitoredEthernetInterfaces.map { "State:/Network/Interface/\($0)/Link" as CFString }
        SCDynamicStoreSetNotificationKeys(store, nil, keys as CFArray)

        if let runLoopSource = SCDynamicStoreCreateRunLoopSource(nil, store, 0) {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
        }

        ethernetCableConnected = isEthernetConnected()
    }
}
