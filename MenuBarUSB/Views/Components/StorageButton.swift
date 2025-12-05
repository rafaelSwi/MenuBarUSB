//
//  StorageButton.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth Swierczynski on 01/12/25.
//

import SwiftUI

struct StorageButton: View {
    let type: CodableType
    let showStorage: Bool = false
    let action: () -> Void
    
    @State private var hovering = false
    
    enum CodableType {
        case sound
        case soundAssociation
        case stored
        case renamed
        case camouflaged
        case heritage
        case pinned
        case log
    }
    
    private struct CodableTypeProperty {
        let labelKey: String
        let icon: String
        let legacyIcon: String
        let count: Int
    }
    
    private var codableProperty: CodableTypeProperty {
        switch type {
        case .pinned:
            return CodableTypeProperty(
                labelKey: "clear_all_pins",
                icon: "pin",
                legacyIcon: "pin",
                count: CSM.Pin.count
            )
        case .renamed:
            return CodableTypeProperty(
                labelKey: "clear_all_renamed",
                icon: "pencil.and.scribble",
                legacyIcon: "pencil",
                count: CSM.Renamed.count
            )
        case .camouflaged:
            return CodableTypeProperty(
                labelKey: "clear_all_hidden",
                icon: "eye",
                legacyIcon: "eye",
                count: CSM.Camouflaged.count
            )
        case .heritage:
            return CodableTypeProperty(
                labelKey: "clear_all_inheritances",
                icon: "app.connected.to.app.below.fill",
                legacyIcon: "app.connected.to.app.below.fill",
                count: CSM.Heritage.count
            )
        case .soundAssociation:
            return CodableTypeProperty(
                labelKey: "undo_all_devices_sound_associations",
                icon: "speaker.wave.3",
                legacyIcon: "speaker.wave.3",
                count: CSM.SoundDevices.count
            )
        case .sound:
            return CodableTypeProperty(
                labelKey: "clear_all_custom_hardware_sounds",
                icon: "document",
                legacyIcon: "waveform",
                count: CSM.Sound.count
            )
        case .stored:
            return CodableTypeProperty(
                labelKey: "delete_device_history",
                icon: "arrow.clockwise",
                legacyIcon: "arrow.clockwise",
                count: CSM.Stored.count
            )
        case .log:
            return CodableTypeProperty(
                labelKey: "clear_all_connection_logs",
                icon: "text.document",
                legacyIcon: "text.aligncenter",
                count: CSM.ConnectionLog.count
            )
        }
    }
    
    private var correctIcon: String {
        if #available(macOS 15.0, *) {
            return codableProperty.icon
        } else {
            return codableProperty.legacyIcon
        }
    }
    
    private var storageUsage: String {
        typealias misc = Utils.Miscellaneous
        
        switch type {
        case .pinned:
            return misc.formatBytes(misc.sizeOfCodableArray(CodableStorageManager.Pin.items))
        case .renamed:
            return misc.formatBytes(misc.sizeOfCodableArray(CodableStorageManager.Renamed.items))
        case .camouflaged:
            return misc.formatBytes(misc.sizeOfCodableArray(CodableStorageManager.Camouflaged.items))
        case .heritage:
            return misc.formatBytes(misc.sizeOfCodableArray(CodableStorageManager.Heritage.items))
        case .soundAssociation:
            return misc.formatBytes(misc.sizeOfCodableArray(CodableStorageManager.SoundDevices.items))
        case .sound:
            return misc.formatBytes(misc.sizeOfCodableArray(CodableStorageManager.Sound.items))
        case .stored:
            return misc.formatBytes(misc.sizeOfCodableArray(CodableStorageManager.Stored.items))
        case .log:
            return misc.formatBytes(misc.sizeOfCodableArray(CodableStorageManager.ConnectionLog.items))
        }
    }

    var body: some View {
        HStack {
            
            Image(systemName: correctIcon)
                .frame(width: 16)

            Button(codableProperty.labelKey.localized) {
                action()
            }

            Spacer()
            
            Group {
                if hovering && codableProperty.count > 0 {
                    Text(storageUsage)
                        .font(.system(size: 10))
                } else {
                    Image(systemName: correctIcon)
                        .font(.system(size: 9))

                    Text("\(codableProperty.count)")
                        .font(.subheadline)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: hovering)
        }
        .opacity(codableProperty.count > 0 ? 1.0 : 0.4)
        .help("\("storage_category".localized): \(storageUsage)")
        .onHover { hovering = $0 }
    }
}
