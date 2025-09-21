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
    
    @ViewBuilder
    func colorSchemeForce(light: Bool, dark: Bool) -> some View {
        switch (light, dark) {
        case (true, _):
             self.environment(\.colorScheme, .light)
        case (_, true):
             self.environment(\.colorScheme, .dark)
        default:
             self
        }
    }
    
}
