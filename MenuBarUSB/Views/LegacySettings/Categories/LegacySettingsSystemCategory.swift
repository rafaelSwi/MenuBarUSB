//
//  LegacySettingsSystemCategory.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI
import ServiceManagement

struct LegacySettingsSystemCategory: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    
    @State private var isPlayingSound = false
    
    @Binding var activeRowID: UUID?
    
    @AS(Key.launchAtLogin) private var launchAtLogin = false
    @AS(Key.showNotifications) private var showNotifications = false
    @AS(Key.newVersionNotification) private var newVersionNotification = false
    @AS(Key.reduceTransparency) private var reduceTransparency = false
    @AS(Key.disableNotifCooldown) private var disableNotifCooldown = false
    @AS(Key.playHardwareSound) private var playHardwareSound = false
    @AS(Key.hardwareSound) private var hardwareSound: String = ""

    private func toggleLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Error:", error)
        }
    }
    
    var body: some View {
        ToggleRow(
            label: "open_on_startup",
            description: "open_on_startup_description",
            binding: $launchAtLogin,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { value in
                toggleLoginItem(enabled: value)
            }
        )
        ToggleRow(
            label: "new_version_notification",
            description: "new_version_notification_description",
            binding: $newVersionNotification,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { _ in }
        )
        ToggleRow(
            label: "show_notification",
            description: "show_notification_description",
            binding: $showNotifications,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { value in
                if value == false {
                    disableNotifCooldown = false
                } else {
                    Utils.System.requestNotificationPermission()
                }
            }
        )
        ToggleRow(
            label: "disable_notification_cooldown",
            description: "disable_notification_cooldown_description",
            binding: $disableNotifCooldown,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            disabled: showNotifications == false,
            onToggle: { _ in }
        )
        ToggleRow(
            label: "play_hardware_sound",
            description: "play_hardware_sound_description",
            binding: $playHardwareSound,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { _ in }
        )
        HStack {
            Menu {
                ForEach(HardwareSound.all, id: \.uniqueId) { sound in
                    Button(LocalizedStringKey(sound.titleKey)) {
                        hardwareSound = sound.uniqueId
                    }
                }
            } label: {
                let sound = HardwareSound[hardwareSound]
                let title = LocalizedStringKey(sound?.titleKey ?? "none_default")
                Text(title)
            }
            .contextMenu {
                Button("undo_all_devices_sound_associations") {
                    CSM.SoundDevices.clear()
                    Utils.App.restart()
                }
            }

            if hardwareSound != "" {
                Button {
                    isPlayingSound = true
                    let sound = HardwareSound[hardwareSound]
                    Utils.System.playSound(sound?.connect)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        Utils.System.playSound(sound?.disconnect)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                        isPlayingSound = false
                    }
                } label: {
                    Image(systemName: "play.fill")
                }
                .buttonStyle(.borderless)
            }
            Spacer()
        }
        .frame(maxWidth: 290)
        .disabled(isPlayingSound)
        .opacity(playHardwareSound ? 1.0 : 0.1)
    }
}
