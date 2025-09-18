//
//  View+Background.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 18/09/25.
//

import SwiftUI

extension View {
    @ViewBuilder
    func appBackground(_ reduceTransparency: Bool) -> some View {
        if reduceTransparency {
            self
                .background(.ultraThickMaterial)
        } else {
            self
        }
    }
}
