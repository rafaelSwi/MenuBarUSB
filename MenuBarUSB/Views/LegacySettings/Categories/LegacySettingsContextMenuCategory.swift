//
//  LegacySettingsContextMenuCategory.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct LegacySettingsContextMenuCategory: View {
    
    @EnvironmentObject var manager: USBDeviceManager
    
    @Binding var activeRowID: UUID?
    
    @AS(Key.disableContextMenuSearch) private var disableContextMenuSearch = false
    @AS(Key.disableContextMenuHeritage) private var disableContextMenuHeritage = false
    @AS(Key.contextMenuCopyAll) private var contextMenuCopyAll = false
    @AS(Key.searchEngine) private var searchEngine: SearchEngine = .google
    
    var body: some View {
        Text("rmb_explanation")
            .font(.title2)
            .italic()
            .padding(.vertical)
            .opacity(0.8)

        ToggleRow(
            label: "disable_context_menu_search",
            description: "disable_context_menu_search_description",
            binding: $disableContextMenuSearch,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { _ in }
        )
        ToggleRow(
            label: "disable_context_menu_heritage",
            description: "disable_context_menu_heritage_description",
            binding: $disableContextMenuHeritage,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { _ in }
        )
        ToggleRow(
            label: "allow_copying_individual",
            description: "allow_copying_individual_description",
            binding: $contextMenuCopyAll,
            activeRowID: $activeRowID,
            incompatibilities: nil,
            onToggle: { _ in }
        )
        HStack {
            Text("search_engine")
            Menu(searchEngine.rawValue) {
                ForEach(SearchEngine.allCases, id: \.self) { engine in
                    Button {
                        searchEngine = engine
                    } label: {
                        Text(engine.rawValue)
                    }
                }
            }
            .disabled(disableContextMenuSearch)
            .frame(maxWidth: 100)
        }
    }
}
