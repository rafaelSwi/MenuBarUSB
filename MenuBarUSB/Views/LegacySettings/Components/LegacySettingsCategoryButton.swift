//
//  LegacySettingsCategoryButton.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct LegacySettingsCategoryButton: View {
    
    @State var label: String
    @Binding var toggle: Bool
    
    var untoggleAll: () -> Void
    
    private func manageShowOptions() {
        if toggle {
            toggle.toggle()
        } else {
            untoggleAll()
            toggle = true
        }
    }
    
    var body: some View {
        HStack {
            Text(label.localized)
                .font(.system(size: 14.5))
                .fontWeight(.light)
                .foregroundColor(.primary)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .lineLimit(1)
        }
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(toggle ? Color.accentColor.opacity(0.2) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            manageShowOptions()
        }
    }
}
