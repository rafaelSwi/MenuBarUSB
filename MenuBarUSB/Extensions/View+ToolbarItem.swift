//
//  View+ToolbarItem.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 14/11/25.
//

import SwiftUI

extension View {
    @ViewBuilder
    func toolbarItem() -> some View {
        font(.system(size: 13))
            .frame(width: 21, height: 21)
            .padding(1.5)
            .cornerRadius(2)
    }
}
