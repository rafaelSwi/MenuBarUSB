//
//  ToggleRow.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth Swierczynski on 31/08/25.
//

import SwiftUI
import Combine

struct ToggleRow: View {
    let label: String
    let description: String
    @Binding var binding: Bool
    @Binding var showMessage: Bool
    var disabled: Bool = false
    var onToggle: (Bool) -> Void
    var untoggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Toggle(label, isOn: $binding)
                    .onChange(of: binding) { newValue in
                        onToggle(newValue)
                    }
                    .toggleStyle(.checkbox)
                    .disabled(disabled)
                
                Button {
                    if (showMessage == true) {
                        showMessage.toggle();
                    } else {
                        untoggle()
                        showMessage.toggle()
                    }
                    
                } label: {
                    Image(systemName: "info.circle")
                        .opacity(0.4)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            
            if showMessage {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
