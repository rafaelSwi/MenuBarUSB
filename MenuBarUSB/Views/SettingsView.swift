//
//  AboutView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import SwiftUI
import ServiceManagement
import AppKit

struct SettingsView: View {
    @EnvironmentObject var manager: USBDeviceManager
    
    @Binding var currentWindow: AppWindow
    
    @State private var showMessage: Bool = false
    @State private var showRenameDevices: Bool = false
    @State private var showCamouflagedDevices: Bool = false
    
    @State private var selectedDeviceToCamouflage: USBDevice?;
    @State private var selectedDeviceToRename: USBDevice?;
    @State private var inputText: String = "";
    
    @State private var tryingToResetSettings = false;
    @State private var checkingUpdate = false
    @State private var updateAvailable = false
    @State private var latestVersion: String = ""
    @State private var releaseURL: URL? = nil
    
    @State private var showSystemOptions = false;
    @State private var showIconOptions = false;
    @State private var showInterfaceOptions = false;
    @State private var showInfoOptions = false;
    @State private var showHeritageOptions = false;
    @State private var showOthersOptions = false;
    
    @State private var invisibleIconOptions = false;
    @State private var invisibleInterfaceOptions = false;
    @State private var invisibleInfoOptions = false;
    @State private var invisibleHeritageOptions = false;
    @State private var invisibleOthersOptions = false;
    
    @State private var showLaunchAtLoginDescription: Bool = false;
    @State private var showConvertHexaDescription: Bool = false;
    @State private var showLongListDescription: Bool = false;
    @State private var showShowNotificationsDescription: Bool = false;
    @State private var showShowPortMaxDescription: Bool = false;
    @State private var showHideTechInfoDescription: Bool = false
    @State private var showRenamedIndicatorDescription: Bool = false;
    @State private var showCamouflagedIndicatorDescription: Bool = false;
    @State private var showReduceTransparencyDescription: Bool = false;
    @State private var showDisableNotifCooldownDescription: Bool = false;
    @State private var showDisableInheritanceLayoutDescription: Bool = false;
    @State private var showForceDarkModeDescription: Bool = false;
    @State private var showForceLightModeDescription: Bool = false;
    @State private var showIncreasedIndentationGapDescription: Bool = false;
    @State private var showHideSecondaryInfoDescription: Bool = false;
    @State private var showHideUpdateDescription: Bool = false;
    @State private var showHideDonateDescription: Bool = false;
    @State private var showNoTextButtonsDescription: Bool = false;
    @State private var showHideCountDescription: Bool = false;
    @State private var showHideMenubarIconDescription: Bool = false;
    @State private var showRestartButtonDescription: Bool = false;
    @State private var showMouseHoverInfoDescription: Bool = false;
    @State private var showProfilerButtonDescription: Bool = false;
    
    @AppStorage(StorageKeys.launchAtLogin) private var launchAtLogin = false
    @AppStorage(StorageKeys.convertHexa) private var convertHexa = false
    @AppStorage(StorageKeys.longList) private var longList = false
    @AppStorage(StorageKeys.hideTechInfo) private var hideTechInfo = false
    @AppStorage(StorageKeys.showPortMax) private var showPortMax = false
    @AppStorage(StorageKeys.renamedIndicator) private var renamedIndicator = false
    @AppStorage(StorageKeys.camouflagedIndicator) private var camouflagedIndicator = false
    @AppStorage(StorageKeys.showNotifications) private var showNotifications = false
    @AppStorage(StorageKeys.reduceTransparency) private var reduceTransparency = false
    @AppStorage(StorageKeys.disableNotifCooldown) private var disableNotifCooldown = false
    @AppStorage(StorageKeys.disableInheritanceLayout) private var disableInheritanceLayout = false
    @AppStorage(StorageKeys.forceDarkMode) private var forceDarkMode = false
    @AppStorage(StorageKeys.forceLightMode) private var forceLightMode = false
    @AppStorage(StorageKeys.increasedIndentationGap) private var increasedIndentationGap = false
    @AppStorage(StorageKeys.hideSecondaryInfo) private var hideSecondaryInfo = false
    @AppStorage(StorageKeys.hideUpdate) private var hideUpdate = false
    @AppStorage(StorageKeys.hideDonate) private var hideDonate = false
    @AppStorage(StorageKeys.noTextButtons) private var noTextButtons = false
    @AppStorage(StorageKeys.hideCount) private var hideCount = false
    @AppStorage(StorageKeys.numberRepresentation) private var numberRepresentation: NumberRepresentation = .base10
    @AppStorage(StorageKeys.macBarIcon) private var macBarIcon: String = "cable.connector"
    @AppStorage(StorageKeys.hideMenubarIcon) private var hideMenubarIcon = false
    @AppStorage(StorageKeys.restartButton) private var restartButton = false
    @AppStorage(StorageKeys.mouseHoverInfo) private var mouseHoverInfo = false
    @AppStorage(StorageKeys.profilerButton) private var profilerButton = false
    
    @CodableAppStorage(StorageKeys.renamedDevices) private var renamedDevices: [RenamedDevice] = []
    @CodableAppStorage(StorageKeys.camouflagedDevices) private var camouflagedDevices: [CamouflagedDevice] = []
    @CodableAppStorage(StorageKeys.inheritedDevices) private var inheritedDevices: [HeritageDevice] = []
    
    func untoggleAllDesc() {
        showShowPortMaxDescription = false;
        showLongListDescription = false;
        showConvertHexaDescription = false;
        showRenamedIndicatorDescription = false;
        showCamouflagedIndicatorDescription = false;
        showHideTechInfoDescription = false;
        showShowNotificationsDescription = false;
        showReduceTransparencyDescription = false;
        showDisableNotifCooldownDescription = false;
        showLaunchAtLoginDescription = false;
        showDisableInheritanceLayoutDescription = false;
        showForceDarkModeDescription = false;
        showForceLightModeDescription = false;
        showIncreasedIndentationGapDescription = false;
        showHideSecondaryInfoDescription = false;
        showHideUpdateDescription = false;
        showHideDonateDescription = false;
        showNoTextButtonsDescription = false;
        showHideCountDescription = false;
        showHideMenubarIconDescription = false;
        showRestartButtonDescription = false;
        showMouseHoverInfoDescription = false;
        showProfilerButtonDescription = false;
    }
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }
    
    func killApp() {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-n", Bundle.main.bundlePath]
        task.launch()
        NSApp.terminate(nil)
    }
    
    func openSysInfo() {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [
            "-b", "com.apple.SystemProfiler",
            "--args", "SPUSBDataType"
        ]
        try? task.run()
    }
    
    func resetAppData() {
        let fileManager = FileManager.default
        
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
        }
        
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
           let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first,
           let bundleID = Bundle.main.bundleIdentifier {
            
            let appSupportPath = appSupport.appendingPathComponent(bundleID).path
            let cachesPath = caches.appendingPathComponent(bundleID).path
            
            try? fileManager.removeItem(atPath: appSupportPath)
            try? fileManager.removeItem(atPath: cachesPath)
        }
    }
    
    func getIcons() -> [String] {
        var icons: [String] = [
            "cable.connector",
            "app.connected.to.app.below.fill",
            "rectangle.connected.to.line.below",
            "mediastick",
            "sdcard",
            "sdcard.fill",
            "bolt.ring.closed",
            "bolt",
            "bolt.fill",
            "wrench.and.screwdriver",
            "wrench.and.screwdriver.fill",
            "externaldrive.connected.to.line.below",
            "externaldrive.connected.to.line.below.fill",
        ]
        if #available(macOS 15.0, *) {
            icons.append(contentsOf: [
                "powerplug.portrait",
                "powerplug.portrait.fill",
                "powercord",
                "powercord.fill",
                "cat.fill",
                "dog.fill",
            ])
        }
        if #available(macOS 26.0, *) {
            icons.append(contentsOf: [
                "inset.filled.topthird.middlethird.bottomthird.rectangle",
            ])
        }
        return icons
    }
    
    func untoggleShowOptions() {
        showSystemOptions = false
        showInterfaceOptions = false
        showInfoOptions = false
        showHeritageOptions = false
        showOthersOptions = false
        showIconOptions = false
    }
    
    func manageShowOptions(exception: inout Bool) {
        if (exception) {
            exception = !exception
        } else {
            untoggleShowOptions()
            exception = true
        }
    }
    
    public func toggleLoginItem(enabled: Bool) {
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
        
        let anyBottomOptionInUse: Bool = showRenameDevices || showCamouflagedDevices
        
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MenuBarUSB")
                        .font(.title2)
                        .bold()
                    Text(String(format: NSLocalizedString("version", comment: "APP VERSION"), appVersion))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                if updateAvailable, let releaseURL {
                    HStack(alignment: .center, spacing: 6) {
                        Button(action: {
                            updateAvailable = false
                            latestVersion = ""
                        }) {
                            Image(systemName: "x.circle")
                        }
                        
                        Link("\(String(localized: "open_download_page")) (v\(latestVersion))", destination: releaseURL)
                            .buttonStyle(.borderedProminent)
                    }
                }
                
                if !updateAvailable {
                    
                    HStack {
                        if (!hideUpdate) {
                            Button {
                                checkForUpdate()
                            } label: {
                                if checkingUpdate {
                                    ProgressView()
                                } else {
                                    Label(!latestVersion.isEmpty ? "updated" : "check_for_updates", systemImage: "checkmark.circle")
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if (!hideDonate) {
                            Button {
                                currentWindow = .donate
                            } label: {
                                Label("donate", systemImage: "hand.thumbsup.circle")
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                
                HStack {
                    Image(systemName: showSystemOptions ? "chevron.down" : "chevron.up")
                    Text(String(localized: "systemCategory"))
                        .font(.system(size: 13.5))
                        .fontWeight(.light)
                }
                .onTapGesture {
                    manageShowOptions(exception: &showSystemOptions)
                }
                
                if (showSystemOptions) {
                    ToggleRow(
                        label: String(localized: "open_on_startup"),
                        description: String(localized: "open_on_startup_description"),
                        binding: $launchAtLogin,
                        showMessage: $showLaunchAtLoginDescription,
                        incompatibilities: nil,
                        onToggle: { value in
                            toggleLoginItem(enabled: value)
                        },
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "show_notification"),
                        description: String(localized: "show_notification_description"),
                        binding: $showNotifications,
                        showMessage: $showShowNotificationsDescription,
                        incompatibilities: nil,
                        onToggle: { value in
                            if (value == false) {
                                disableNotifCooldown = false
                            }
                        },
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "disable_notification_cooldown"),
                        description: String(localized: "disable_notification_cooldown_description"),
                        binding: $disableNotifCooldown,
                        showMessage: $showDisableNotifCooldownDescription,
                        incompatibilities: nil,
                        disabled: showNotifications == false,
                        onToggle: {_ in},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                }
                
                HStack {
                    Image(systemName: showIconOptions ? "chevron.down" : "chevron.up")
                    Text(String(localized: "icon_category"))
                        .font(.system(size: 13.5))
                        .fontWeight(.light)
                }
                .onTapGesture {
                    manageShowOptions(exception: &showIconOptions)
                }
                
                if (showIconOptions) {
                    VStack(alignment: .leading, spacing: 16) {
                        ToggleRow(
                            label: String(localized: "hide_menubar_icon"),
                            description: String(localized: "hide_menubar_icon_description"),
                            binding: $hideMenubarIcon,
                            showMessage: $showHideMenubarIconDescription,
                            incompatibilities: nil,
                            disabled: hideCount,
                            onToggle: { _ in hideCount = false },
                            untoggle: { untoggleAllDesc() }
                        )
                        ToggleRow(
                            label: String(localized: "hide_count"),
                            description: String(localized: "hide_count_description"),
                            binding: $hideCount,
                            showMessage: $showHideCountDescription,
                            incompatibilities: nil,
                            disabled: hideMenubarIcon,
                            onToggle: { _ in hideMenubarIcon = false },
                            untoggle: { untoggleAllDesc() }
                        )
                        
                        HStack(spacing: 12) {
                            if !hideMenubarIcon {
                                Text("icon")
                                Image(systemName: macBarIcon)
                            }
                            if !hideCount {
                                Text("numerical_representation")
                                Text(NumberConverter(manager.devices.count).convert())
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        
                        HStack{
                            Menu {
                                ForEach(getIcons(), id: \.self) { item in
                                    Button {
                                        macBarIcon = item
                                    } label: {
                                        HStack {
                                            Image(systemName: item)
                                            if !hideCount {
                                                Text(NumberConverter(manager.devices.count).convert())
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Label("icon", systemImage: macBarIcon)
                                    .background(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))
                            }
                            .disabled(hideMenubarIcon)
                            
                            Menu(LocalizedStringKey(numberRepresentation.rawValue)) {
                                let nr: [NumberRepresentation] = [.base10, .binary, .egyptian, .greek, .hex, .roman]
                                ForEach(nr, id: \.self) { item in
                                    Button {
                                        numberRepresentation = item
                                        killApp()
                                    } label: {
                                        Text(LocalizedStringKey(item.rawValue))
                                    }
                                }
                            }
                            .disabled(hideCount)
                            .help("numerical_representation")
                        }
                        
                        Text("changes_restart_warning")
                            .font(.footnote)
                            .foregroundColor(.primary)
                            .opacity(0.7)
                            .padding(.bottom, 3)
                    }
                    
                }
                
                HStack {
                    Image(systemName: showInterfaceOptions ? "chevron.down" : "chevron.up")
                    Text(String(localized: "uiCategory"))
                        .font(.system(size: 13.5))
                        .fontWeight(.light)
                }
                .onTapGesture {
                    manageShowOptions(exception: &showInterfaceOptions)
                }
                
                if (showInterfaceOptions) {
                    ToggleRow(
                        label: String(localized: "hide_technical_info"),
                        description: String(localized: "hide_technical_info_description"),
                        binding: $hideTechInfo,
                        showMessage: $showHideTechInfoDescription,
                        incompatibilities: [showPortMax, convertHexa],
                        onToggle: { value in
                            if (value == true) {
                                showPortMax = false
                                convertHexa = false
                            } else {
                                mouseHoverInfo = false
                            }
                        },
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "mouse_hover_info"),
                        description: String(localized: "mouse_hover_info_description"),
                        binding: $mouseHoverInfo,
                        showMessage: $showMouseHoverInfoDescription,
                        incompatibilities: nil,
                        disabled: !hideTechInfo,
                        onToggle: { _ in},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "hide_secondary_info"),
                        description: String(localized: "hide_secondary_info_description"),
                        binding: $hideSecondaryInfo,
                        showMessage: $showHideSecondaryInfoDescription,
                        incompatibilities: [showPortMax, convertHexa],
                        onToggle: { value in
                            if (value == true) {
                                showPortMax = false
                                convertHexa = false
                            }
                        },
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "long_list"),
                        description: String(localized: "long_list_description"),
                        binding: $longList,
                        showMessage: $showLongListDescription,
                        incompatibilities: nil,
                        onToggle: {_ in},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "reduce_transparency"),
                        description: String(localized: "reduce_transparency_description"),
                        binding: $reduceTransparency,
                        showMessage: $showReduceTransparencyDescription,
                        incompatibilities: nil,
                        onToggle: {_ in},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "force_dark_mode"),
                        description: String(localized: "force_dark_mode_description"),
                        binding: $forceDarkMode,
                        showMessage: $showForceDarkModeDescription,
                        incompatibilities: [forceLightMode],
                        disabled: forceLightMode,
                        onToggle: {_ in forceLightMode = false},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "force_light_mode"),
                        description: String(localized: "force_light_mode_description"),
                        binding: $forceLightMode,
                        showMessage: $showForceLightModeDescription,
                        incompatibilities: [forceDarkMode],
                        disabled: forceDarkMode,
                        onToggle: {_ in forceDarkMode = false},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "hidden_indicator"),
                        description: String(localized: "hidden_indicator_description"),
                        binding: $camouflagedIndicator,
                        showMessage: $showCamouflagedIndicatorDescription,
                        incompatibilities: nil,
                        onToggle: {_ in },
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "renamed_indicator"),
                        description: String(localized: "renamed_indicator_description"),
                        binding: $renamedIndicator,
                        showMessage: $showRenamedIndicatorDescription,
                        incompatibilities: nil,
                        onToggle: {_ in},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                }
                
                HStack {
                    Image(systemName: showInfoOptions ? "chevron.down" : "chevron.up")
                    Text(String(localized: "usbCategory"))
                        .font(.system(size: 13.5))
                        .fontWeight(.light)
                }
                .onTapGesture {
                    manageShowOptions(exception: &showInfoOptions)
                }
                
                if (showInfoOptions) {
                    
                    Button {
                        showRenameDevices.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                            Text("rename_device")
                        }
                    }
                    .disabled(anyBottomOptionInUse)
                    
                    Button {
                        showCamouflagedDevices.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "eye")
                            Text("hide_device")
                        }
                    }
                    .disabled(anyBottomOptionInUse)
                    
                    ToggleRow(
                        label: String(localized: "show_port_max"),
                        description: String(localized: "show_port_max_description"),
                        binding: $showPortMax,
                        showMessage: $showShowPortMaxDescription,
                        incompatibilities: nil,
                        disabled: hideTechInfo,
                        onToggle: {_ in},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "convert_hexa"),
                        description: String(localized: "convert_hexa_description"),
                        binding: $convertHexa,
                        showMessage: $showConvertHexaDescription,
                        incompatibilities: nil,
                        disabled: hideTechInfo,
                        onToggle: {_ in},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                }
                
                HStack {
                    Image(systemName: showHeritageOptions ? "chevron.down" : "chevron.up")
                    Text(String(localized: "heritageCategory"))
                        .font(.system(size: 13.5))
                        .fontWeight(.light)
                }
                .onTapGesture {
                    manageShowOptions(exception: &showHeritageOptions)
                }
                
                if (showHeritageOptions) {
                    
                    Button {
                        currentWindow = .heritage
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("create_inheritance")
                        }
                    }
                    .disabled(anyBottomOptionInUse)
                    
                    Button {
                        currentWindow = .inheritanceTree
                    } label: {
                        HStack {
                            Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                            Text("view_inheritance_tree")
                        }
                    }
                    .disabled(anyBottomOptionInUse)
                    
                    ToggleRow(
                        label: String(localized: "disable_inheritance_layout"),
                        description: String(localized: "disable_inheritance_layout_description"),
                        binding: $disableInheritanceLayout,
                        showMessage: $showDisableInheritanceLayoutDescription,
                        incompatibilities: [increasedIndentationGap],
                        onToggle: {_ in increasedIndentationGap = false},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "increased_indentation_gap"),
                        description: String(localized: "increased_indentation_gap_description"),
                        binding: $increasedIndentationGap,
                        showMessage: $showIncreasedIndentationGapDescription,
                        incompatibilities: nil,
                        disabled: disableInheritanceLayout,
                        onToggle: {_ in},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                }
                
                HStack {
                    Image(systemName: showOthersOptions ? "chevron.down" : "chevron.up")
                    Text(String(localized: "othersCategory"))
                        .font(.system(size: 13.5))
                        .fontWeight(.light)
                }
                .onTapGesture {
                    manageShowOptions(exception: &showOthersOptions)
                }
                
                if (showOthersOptions) {
                    
                    ToggleRow(
                        label: String(localized: "hide_check_update"),
                        description: String(localized: "hide_check_update_description"),
                        binding: $hideUpdate,
                        showMessage: $showHideUpdateDescription,
                        incompatibilities: nil,
                        onToggle: {_ in},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "hide_donate"),
                        description: String(localized: "hide_donate_description"),
                        binding: $hideDonate,
                        showMessage: $showHideDonateDescription,
                        incompatibilities: nil,
                        onToggle: {_ in},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "no_text_buttons"),
                        description: String(localized: "no_text_buttons_description"),
                        binding: $noTextButtons,
                        showMessage: $showNoTextButtonsDescription,
                        incompatibilities: nil,
                        onToggle: {_ in},
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    ToggleRow(
                        label: String(localized: "restart_button"),
                        description: String(localized: "restart_button_description"),
                        binding: $restartButton,
                        showMessage: $showRestartButtonDescription,
                        incompatibilities: [profilerButton],
                        onToggle: { value in
                            if (value == true) {
                                profilerButton = false;
                            }
                        },
                        untoggle: {
                            untoggleAllDesc();
                        }
                    )
                    if #available(macOS 15.0, *) {
                        ToggleRow(
                            label: String(localized: "profiler_shortcut"),
                            description: String(localized: "profiler_shortcut_description"),
                            binding: $profilerButton,
                            showMessage: $showProfilerButtonDescription,
                            incompatibilities: [restartButton],
                            onToggle: { value in
                                if (value == true) {
                                    restartButton = false;
                                }
                            },
                            untoggle: {
                                untoggleAllDesc();
                            }
                        )
                    }
                    
                    if #available(macOS 15.0, *) {
                        Button {
                            openSysInfo()
                        } label: {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                Text("open_profiler")
                            }
                        }
                        .disabled(tryingToResetSettings)
                    }
                    
                    Button {
                        tryingToResetSettings = true;
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill.badge.gearshape")
                            Text("restore_default_settings")
                        }
                    }
                    .disabled(tryingToResetSettings)
                    
                    if (tryingToResetSettings) {
                        HStack(spacing: 12) {
                            Text("are_you_sure")
                            Button("no") {
                                tryingToResetSettings = false;
                            }
                            Button("yes_confirm") {
                                resetAppData()
                                tryingToResetSettings = false;
                                showOthersOptions = false;
                                if let sound = NSSound(named: NSSound.Name("Funk")) {
                                    sound.play()
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                    killApp()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    
                }
                
                
                
            }
            
            Spacer()
            
            VStack(alignment: .leading) {
                
                if (anyBottomOptionInUse) {
                    Button("cancel") {
                        showRenameDevices = false
                        showCamouflagedDevices = false
                        selectedDeviceToRename = nil
                        selectedDeviceToCamouflage = nil
                        inputText = ""
                    }
                }
                
                HStack {
                    
                    Spacer()
                    
                    if (!anyBottomOptionInUse) {
                        Button(action: {currentWindow = .devices}) {
                            Label("back", systemImage: "arrow.uturn.backward")
                        }
                    }
                    
                }
                
                if (anyBottomOptionInUse) {
                    Divider()
                }
                
                if showCamouflagedDevices {
                    HStack(spacing: 12) {
                        Menu {
                            ForEach(manager.devices) { device in
                                let renamedDevice = renamedDevices.first { $0.deviceId == USBDevice.uniqueId(device) }
                                let buttonLabel = renamedDevice?.name ?? device.name
                                Button(buttonLabel) {
                                    selectedDeviceToCamouflage = device
                                }
                            }
                        } label: {
                            Text(selectedDeviceToCamouflage?.name ?? String(localized: "device"))
                        }
                        
                        if selectedDeviceToCamouflage != nil {
                            
                            if (inheritedDevices.contains { $0.inheritsFrom == USBDevice.uniqueId(selectedDeviceToCamouflage!) }) {
                                Text("cant_hide_heir")
                                    .font(.subheadline)
                            } else {
                                Button("confirm") {
                                    let uniqueId = USBDevice.uniqueId(selectedDeviceToCamouflage!)
                                    let newDevice = CamouflagedDevice(deviceId: uniqueId)
                                    camouflagedDevices.removeAll { $0.deviceId == uniqueId }
                                    camouflagedDevices.append(newDevice)
                                    selectedDeviceToCamouflage = nil
                                    showCamouflagedDevices = false
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        
                        if selectedDeviceToCamouflage == nil && !camouflagedDevices.isEmpty {
                            Button("undo_all") {
                                camouflagedDevices.removeAll()
                                showCamouflagedDevices = false
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                if showRenameDevices {
                    HStack(spacing: 12) {
                        Menu {
                            ForEach(manager.devices) { device in
                                let renamedDevice = renamedDevices.first { $0.deviceId == USBDevice.uniqueId(device) }
                                let buttonLabel = renamedDevice?.name ?? device.name
                                Button(buttonLabel) {
                                    inputText = ""
                                    selectedDeviceToRename = device
                                }
                            }
                        } label: {
                            Text(selectedDeviceToRename?.name ?? String(localized: "device"))
                        }
                        
                        if selectedDeviceToRename != nil {
                            TextFieldWithLimit(
                                text: $inputText,
                                placeholder: String(localized: "insert_new_name"),
                                maxLength: 30
                            )
                            .frame(width: 190)
                            .help("renaming_help")
                            
                            Button(String(localized: "confirm")) {
                                let uniqueId = USBDevice.uniqueId(selectedDeviceToRename!)
                                if inputText.isEmpty {
                                    renamedDevices.removeAll { $0.deviceId == uniqueId }
                                } else {
                                    renamedDevices.removeAll { $0.deviceId == uniqueId }
                                    renamedDevices.append(RenamedDevice(deviceId: uniqueId, name: inputText))
                                }
                                inputText = ""
                                selectedDeviceToRename = nil
                                showRenameDevices = false
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        
                        if selectedDeviceToRename == nil && !renamedDevices.isEmpty {
                            Button(String(localized: "undo_all")) {
                                renamedDevices.removeAll()
                                showRenameDevices = false
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            
            
        }
        .padding(10)
        .frame(minWidth: 465, minHeight: 600)
        .appBackground(reduceTransparency)
    }
    
    private func checkForUpdate() {
        checkingUpdate = true
        updateAvailable = false
        latestVersion = ""
        releaseURL = nil
        
        guard let url = URL(string: "https://api.github.com/repos/rafaelSwi/MenuBarUSB/releases/latest") else {
            checkingUpdate = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            defer { checkingUpdate = false }
            guard let data = data, error == nil else { return }
            
            if let release = try? JSONDecoder().decode(GitHubRelease.self, from: data) {
                let latest = release.tag_name.replacingOccurrences(of: "v", with: "")
                latestVersion = latest
                releaseURL = URL(string: release.html_url)
                
                DispatchQueue.main.async {
                    updateAvailable = isVersion(appVersion, olderThan: latest)
                }
            }
        }.resume()
    }
    
    private func isVersion(_ v1: String, olderThan v2: String) -> Bool {
        let v1Components = v1.split(separator: ".").compactMap { Int($0) }
        let v2Components = v2.split(separator: ".").compactMap { Int($0) }
        for (a, b) in zip(v1Components, v2Components) {
            if a < b { return true }
            if a > b { return false }
        }
        return v1Components.count < v2Components.count
    }
}
