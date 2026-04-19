//
//  SettingsOthersCategory.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct SettingsOthersCategory: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    
    @Binding var activeRowID: UUID?
        
    @AS(Key.settingsCategory) private var category: SettingsCategory = .system
    @AS(Key.forceEnglish) private var forceEnglish = false
    @AS(Key.listToolBar) private var listToolBar = false
    @AS(Key.hideUpdate) private var hideUpdate = false
    @AS(Key.hideDonate) private var hideDonate = false
    @AS(Key.disableHaptic) private var disableHaptic = false
    @AS(Key.noTextButtons) private var noTextButtons = false
    @AS(Key.profilerButton) private var profilerButton = false
    @AS(Key.trafficButton) private var trafficButton = false
    @AS(Key.windowWidth) private var windowWidth: WindowWidth = .normal
    
    private func setWindowWidth(increase: Bool) {
        let order: [WindowWidth] = [.normal, .big, .veryBig, .huge]
        guard let index = order.firstIndex(of: windowWidth) else { return }
        
        let nextIndex = index + (increase ? 1 : -1)
        if order.indices.contains(nextIndex) {
            windowWidth = order[nextIndex]
        }
        category = .system
        category = .others
    }
    
    private var windowWidthLabel: String {
        var width = ""
        switch windowWidth {
        case .normal:
            width = "window_size_normal"
        case .big:
            width = "window_size_big"
        case .veryBig:
            width = "window_size_verybig"
        case .huge:
            width = "window_size_huge"
        }
        return width.localized
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if Locale.current.language.languageCode?.identifier != "en" {
                ToggleRow(
                    label: "force_english",
                    description: "force_english_description",
                    binding: $forceEnglish,
                    activeRowID: $activeRowID,
                    incompatibilities: nil,
                    willRestart: true,
                    onToggle: { _ in Utils.App.restart() }
                )
            }
            ToggleRow(
                label: "show_toolbar",
                description: "show_toolbar_description",
                binding: $listToolBar,
                activeRowID: $activeRowID,
                incompatibilities: nil,
                onToggle: { _ in }
            )
            ToggleRow(
                label: "hide_check_update",
                description: "hide_check_update_description",
                binding: $hideUpdate,
                activeRowID: $activeRowID,
                incompatibilities: nil,
                onToggle: { _ in }
            )
            ToggleRow(
                label: "hide_donate",
                description: "hide_donate_description",
                binding: $hideDonate,
                activeRowID: $activeRowID,
                incompatibilities: nil,
                onToggle: { _ in }
            )
            ToggleRow(
                label: "disable_haptic_feedback",
                description: "disable_haptic_feedback_description",
                binding: $disableHaptic,
                activeRowID: $activeRowID,
                incompatibilities: nil,
                onToggle: { _ in }
            )
            ToggleRow(
                label: "no_text_buttons",
                description: "no_text_buttons_description",
                binding: $noTextButtons,
                activeRowID: $activeRowID,
                incompatibilities: nil,
                onToggle: { _ in }
            )
            ToggleRow(
                label: "profiler_shortcut",
                description: "profiler_shortcut_description",
                binding: $profilerButton,
                activeRowID: $activeRowID,
                incompatibilities: [trafficButton],
                onToggle: { value in
                    if value == true {
                        trafficButton = false
                    }
                }
            )
            
            HStack {
                
                Text("window_width")
                
                Button {
                    setWindowWidth(increase: false)
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 14, height: 14)
                }
                .disabled(windowWidth == .normal)
                
                Button {
                    setWindowWidth(increase: true)
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 14, height: 14)
                }
                .disabled(windowWidth == .huge)
                
                Text(windowWidthLabel)
                    .font(.footnote)
            }
            .padding(.vertical, 7)
        }
    }
}
