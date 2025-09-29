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
    let incompatibilities: [Bool]?
    var disabled: Bool = false
    var onToggle: (Bool) -> Void
    var untoggle: () -> Void
    
    @State var showIncompatibilityMessage = false
    
    func hasIncompatibility() -> Bool {
        return incompatibilities?.contains(true) ?? false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Toggle(label, isOn: $binding)
                    .onChange(of: binding) { newValue in
                        onToggle(newValue)
                        showIncompatibilityMessage = false
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
                
                if (hasIncompatibility()) {
                    Button {
                        showIncompatibilityMessage.toggle()
                    } label: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color("Warning"))
                            .opacity(0.4)
                    }
                    .buttonStyle(.plain)
                    .help("warning_incompatible_options")
                    .alert("alert", isPresented: $showIncompatibilityMessage) {
                        Button("press_to_close", role: .cancel) { }
                    } message: {
                        Text("warning_incompatible_options")
                    }
                }
                
                Spacer()
            }
            
            if showMessage {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .onAppear {
                        showIncompatibilityMessage = false
                    }
            }
            
        }
        .onAppear {
            showIncompatibilityMessage = false
        }
    }
}
