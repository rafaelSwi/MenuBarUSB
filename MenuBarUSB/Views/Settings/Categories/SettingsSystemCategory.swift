//
//  SettingsSystemCategory.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI
import ServiceManagement

struct SettingsSystemCategory: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    
    @Binding var activeRowID: UUID?
    
    @State private var inputText: String = ""
    @State private var creatingNewAudioSet: Bool = false
    @State private var audioSetConnectedPath: String = ""
    @State private var audioSetDisconnectedPath: String = ""
    @State private var disableButtonsRelatedToSound = false
    @State private var textFieldFocused: Bool = false
    
    @AS(Key.launchAtLogin) private var launchAtLogin = false
    @AS(Key.reduceTransparency) private var reduceTransparency = false
    @AS(Key.forceDarkMode) private var forceDarkMode = false
    @AS(Key.forceLightMode) private var forceLightMode = false
    @AS(Key.newVersionNotification) private var newVersionNotification = false
    @AS(Key.showNotifications) private var showNotifications = false
    @AS(Key.disableNotifCooldown) private var disableNotifCooldown = false
    @AS(Key.playHardwareSound) private var playHardwareSound = false
    @AS(Key.hardwareSound) private var hardwareSound: String = ""
    
    private var isCustomSoundSetSelected: Bool {
        return CSM.Sound[hardwareSound] != nil
    }
    
    private func testHardwareSound(_ seconds: Double = 1.2) {
        let sec = isCustomSoundSetSelected ? seconds * 2.5 : seconds
        disableButtonsRelatedToSound = true
        let sound = HardwareSound[hardwareSound]
        Utils.System.playSound(sound?.connect)
        DispatchQueue.main.asyncAfter(deadline: .now() + sec) {
            Utils.System.playSound(sound?.disconnect)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + sec * 2) {
            disableButtonsRelatedToSound = false
        }
    }
    
    private func playOnlyOneSound(for hardwareSound: String, connect: Bool) {
        playHardwareSound = false
        defer {
            let time: Double = isCustomSoundSetSelected ? 2.5 : 1.5
            DispatchQueue.main.asyncAfter(deadline: .now() + time) {
                playHardwareSound = true
            }
        }
        let sound = HardwareSound[hardwareSound]
        if connect {
            Utils.System.playSound(sound?.connect)
        } else {
            Utils.System.playSound(sound?.disconnect)
        }
    }
    
    private var disableConfirmNewAudioSet: Bool {
        let path1 = audioSetConnectedPath == ""
        let path2 = audioSetDisconnectedPath == ""
        let hasTitle = inputText == ""
        return path1 || path2 || hasTitle
    }
    
    private func deleteHardwareSound(for sound: HardwareSound?) {
        CSM.Sound.remove(withId: sound?.uniqueId ?? "")
        hardwareSound = ""
    }
    
    private func pickAudioFilePath(connect: Bool) {
        pickFile { path in
            if connect {
                audioSetConnectedPath = path ?? ""
            } else {
                audioSetDisconnectedPath = path ?? ""
            }
        }
    }
    
    private func resetAudioSetVariables() {
        inputText = ""
        textFieldFocused = false
        audioSetConnectedPath = ""
        audioSetDisconnectedPath = ""
        creatingNewAudioSet = false
    }
    
    private func confirmNewAudioSet() {
        defer { resetAudioSetVariables() }
        let connect = saveToStorageAndGetPath(audioSetConnectedPath)
        let disconnect = saveToStorageAndGetPath(audioSetDisconnectedPath)
        let item = HardwareSound(
            uniqueId: UUID().uuidString,
            titleKey: inputText,
            connect: connect,
            disconnect: disconnect
        )
        CSM.Sound.add(item)
    }
    
    private func saveToStorageAndGetPath(_ path: String) -> String {
        let fileManager = FileManager.default
        let sourceURL = URL(fileURLWithPath: path)
        
        let appSupport = try! fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        let destination = appSupport.appendingPathComponent(sourceURL.lastPathComponent)
        
        if fileManager.fileExists(atPath: destination.path) {
            try? fileManager.removeItem(at: destination)
        }
        
        try? fileManager.copyItem(at: sourceURL, to: destination)
        return destination.path
    }
    
    private func pickFile(completion: @escaping (String?) -> Void) {
        let dialog = NSOpenPanel()
        dialog.title = "select_file"
        dialog.allowsMultipleSelection = false
        dialog.allowedContentTypes = [.mp3]
        dialog.canChooseDirectories = true
        dialog.canChooseFiles = true
        dialog.canChooseDirectories = false
        
        if dialog.runModal() == .OK {
            completion(dialog.url?.path)
        } else {
            completion(nil)
        }
    }
    
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
        VStack(alignment: .leading, spacing: 3) {
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
                label: "reduce_transparency",
                description: "reduce_transparency_description",
                binding: $reduceTransparency,
                activeRowID: $activeRowID,
                incompatibilities: nil,
                disabled: forceDarkMode || forceLightMode,
                onToggle: { _ in }
            )
            ToggleRow(
                label: "force_dark_mode",
                description: "force_dark_mode_description",
                binding: $forceDarkMode,
                activeRowID: $activeRowID,
                incompatibilities: [forceLightMode],
                onToggle: { value in
                    if value == true {
                        forceLightMode = false
                    }
                }
            )
            ToggleRow(
                label: "force_light_mode",
                description: "force_light_mode_description",
                binding: $forceLightMode,
                activeRowID: $activeRowID,
                incompatibilities: [forceDarkMode],
                onToggle: { value in
                    if value == true {
                        forceDarkMode = false
                    }
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
                    if value {
                        Utils.System.requestNotificationPermission()
                    } else {
                        disableNotifCooldown = false
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
                disabled: disableButtonsRelatedToSound,
                onToggle: { _ in }
            )
            HStack {
                if isCustomSoundSetSelected {
                    Button {
                        deleteHardwareSound(for: CSM.Sound[hardwareSound])
                    } label: {
                        Image(systemName: "trash")
                    }
                    .help("delete")
                }
                Menu {
                    ForEach(HardwareSound.all, id: \.uniqueId) { sound in
                        Button {
                            hardwareSound = sound.uniqueId
                        } label: {
                            Label(LocalizedStringKey(sound.titleKey), systemImage: "speaker.wave.3")
                        }
                    }
                    Divider()
                    Button {
                        creatingNewAudioSet.toggle()
                    } label: {
                        Label("new_set", systemImage: "plus")
                    }
                } label: {
                    let sound = HardwareSound[hardwareSound]
                    let title = LocalizedStringKey(sound?.titleKey ?? "none_default")
                    Text(title)
                }
                .contextMenu {
                    let amount = CSM.SoundDevices.items.count
                    let text = "\("undo_all_devices_sound_associations".localized) (\(amount))"
                    Button(amount > 0 ? text : "no_custom_association_to_undo".localized) {
                        CSM.SoundDevices.clear()
                        manager.refresh()
                    }
                    .disabled(amount <= 0)
                }
                
                if hardwareSound != "" {
                    Button {
                        testHardwareSound()
                    } label: {
                        Image(systemName: "play")
                    }
                    .contextMenu {
                        Button("play_only_connect") {
                            playOnlyOneSound(for: hardwareSound, connect: true)
                        }
                        
                        Button("play_only_disconnect") {
                            playOnlyOneSound(for: hardwareSound, connect: false)
                        }
                    }
                }
                Spacer()
            }
            .frame(maxWidth: 280)
            .disabled(!playHardwareSound)
            .opacity(playHardwareSound ? 1.0 : 0.3)
            .disabled(disableButtonsRelatedToSound)
            
            if creatingNewAudioSet {
                
                Spacer()
                    .frame(height: 3)
                
                CustomTextField(
                    text: $inputText,
                    placeholder: "title",
                    maxLength: 12,
                    isFocused: $textFieldFocused
                )
                .frame(width: 190)
                
                HStack {
                    Button {
                        pickAudioFilePath(connect: true)
                    } label: {
                        Image(systemName: audioSetConnectedPath.isEmpty ? "document" : "checkmark")
                    }
                    Text(audioSetConnectedPath.isEmpty ? "connected_audio_file".localized : audioSetConnectedPath)
                        .lineLimit(1)
                }
                
                HStack {
                    Button {
                        pickAudioFilePath(connect: false)
                    } label: {
                        Image(systemName: audioSetDisconnectedPath.isEmpty ? "document" : "checkmark")
                    }
                    Text(audioSetDisconnectedPath.isEmpty ? "disconnected_audio_file".localized : audioSetDisconnectedPath)
                        .lineLimit(1)
                }
                
                HStack {
                    Button("cancel") {
                        resetAudioSetVariables()
                    }
                    Button("create") {
                        confirmNewAudioSet()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(disableConfirmNewAudioSet)
                }
            }
        }
    }
}
