//
//  LegacySettingsInterfaceCategory.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct LegacySettingsInterfaceCategory: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    
    @Binding var activeRowID: UUID?
    
    @AS(Key.hideTechInfo) private var hideTechInfo = false
    @AS(Key.mouseHoverInfo) private var mouseHoverInfo = false
    @AS(Key.hideSecondaryInfo) private var hideSecondaryInfo = false
    @AS(Key.showScrollBar) private var showScrollBar = false
    @AS(Key.longList) private var longList = false
    @AS(Key.bigNames) private var bigNames = false
    @AS(Key.storeDevices) private var storeDevices = false
    @AS(Key.windowWidth) private var windowWidth: WindowWidth = .normal
    
    private func setWindowWidth(increase: Bool) {
        let order: [WindowWidth] = [.normal, .big, .veryBig, .huge]
        guard let index = order.firstIndex(of: windowWidth) else { return }

        let nextIndex = index + (increase ? 1 : -1)
        if order.indices.contains(nextIndex) {
            windowWidth = order[nextIndex]
        }
    }
    
    private var windowWidthLabel: String {
        switch windowWidth {
        case .normal:
            return "window_size_normal"
        case .big:
            return "window_size_big"
        case .veryBig:
            return "window_size_verybig"
        case .huge:
            return "window_size_huge"
        }
    }
    
    var body: some View {
        ToggleRow(
            label: "hide_technical_info",
            description: "hide_technical_info_description",
            binding: $hideTechInfo,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { value in
                if value == false {
                    mouseHoverInfo = false
                }
            }
        )
        ToggleRow(
            label: "mouse_hover_info",
            description: "mouse_hover_info_description",
            binding: $mouseHoverInfo,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            disabled: !hideTechInfo,
            onToggle: { _ in }
        )
        ToggleRow(
            label: "hide_secondary_info",
            description: "hide_secondary_info_description",
            binding: $hideSecondaryInfo,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { _ in }
        )
        ToggleRow(
            label: "show_scrollbar",
            description: "show_scrollbar_description",
            binding: $showScrollBar,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { _ in }
        )
        ToggleRow(
            label: "long_list",
            description: "long_list_description",
            binding: $longList,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { _ in }
        )
        ToggleRow(
            label: "big_names",
            description: "big_names_description",
            binding: $bigNames,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { _ in }
        )
        ToggleRow(
            label: "show_previously_connected",
            description: "show_previously_connected_description",
            binding: $storeDevices,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { _ in }
        )

        HStack {
            Text("list_width")
            Button {
                setWindowWidth(increase: false)
                manager.refresh()
            } label: {
                Image(systemName: "minus")
                    .frame(width: 14, height: 14)
            }
            .disabled(windowWidth == .normal)

            Button {
                setWindowWidth(increase: true)
                manager.refresh()
            } label: {
                Image(systemName: "plus")
                    .frame(width: 14, height: 14)
            }
            .disabled(windowWidth == .veryBig)

            Text(windowWidthLabel.localized)
                .font(.footnote)
        }
        .padding(.top, 7)
    }
}
