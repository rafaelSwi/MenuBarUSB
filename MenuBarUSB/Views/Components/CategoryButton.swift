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
    var action: (() -> Void)?

    init(
        category: SettingsCategory,
        label: LocalizedStringKey,
        image: String,
        binding: Binding<SettingsCategory>,
        action: (() -> Void)? = nil
    ) {
        self.category = category
        self.label = label
        self.image = image
        _binding = binding
        self.action = action
    }

    @State private var hovering = false

    var body: some View {
        let backgroundColor: Color = {
            if binding == category {
                return Color.blue.opacity(0.25)
            } else if hovering {
                return Color.blue.opacity(0.10)
            } else {
                return Color.clear
            }
        }()

        return HStack {
            VStack {
                Button {
                    binding = category
                    if action != nil {
                        action?()
                    }
                } label: {
                    Image(image)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 14, height: 14)
                        .scaledToFit()
                        .padding(2)
                }
                .background(backgroundColor)
                .cornerRadius(5)
                .onHover { hovering = $0 }
                .help(label)
            }
            Spacer()
        }
    }
}
