//
//  LegacySettingsHorizontalBottomBar.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct LegacySettingsHorizontalBottomBar: View {
    
    @State private var hoveringInfo: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack {
            ZStack(alignment: .bottomLeading) {
                if hoveringInfo {
                    Text("legacy_settings_description")
                        .font(.caption)
                        .offset(y: -40)
                }

                Image(systemName: "info.circle")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .onHover { hovering in
                        hoveringInfo = hovering
                        Utils.System.hapticFeedback()
                    }
                    .padding(4)
            }
            Spacer()
            Button("close") {
                dismiss()
            }
        }
    }
}
