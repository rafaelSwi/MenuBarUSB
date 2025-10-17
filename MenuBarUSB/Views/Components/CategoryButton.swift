//
//  CategoryButton.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth Swierczynski on 11/10/25.
//

import SwiftUI

struct CategoryButton: View {
    let category: SettingsCategory
    let label: LocalizedStringKey
    let image: String
    @Binding var binding: SettingsCategory
    let disabled: Bool

    @State private var hovering = false

    var body: some View {
        let backgroundColor: Color = {
            if binding == category {
                return Color.blue.opacity(0.25)
            } else if hovering && !disabled {
                return Color.blue.opacity(0.10)
            } else {
                return Color.clear
            }
        }()

        return HStack {
            VStack {
                Button {
                    binding = category
                } label: {
                    Image(image)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 14, height: 14)
                        .scaledToFit()
                        .padding(2)
                        .opacity(disabled ? 0.4 : 1.0)
                }
                .disabled(disabled)
                .background(backgroundColor)
                .cornerRadius(5)
                .onHover { hovering = $0 }
                .help(label)
            }
            Spacer()
        }
    }
}
