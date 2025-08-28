//
//  MenuBarUSBApp.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import SwiftUI
import ServiceManagement

@main
struct MenuBarUSBApp: App {
    @StateObject private var manager = USBDeviceManager()
    
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(manager)
            
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "cable.connector")
                Text(String(manager.devices.count))
            }
        }
        .menuBarExtraStyle(.window)
        
        WindowGroup(id: "about") {
            AboutView()
        }
        .handlesExternalEvents(matching: ["about"])
        .windowResizability(.contentSize)
        
    }
}

