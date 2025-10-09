//
//  View+Image.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth Swierczynski on 08/10/25.
//

import SwiftUI


extension View {
    func asImage() -> NSImage {
        let styledRoot = self
            .foregroundStyle(Color.white)
            .environment(\.colorScheme, .dark)

        let view = NSHostingView(rootView: styledRoot)
        let size = view.fittingSize
        view.frame = CGRect(origin: .zero, size: size)
        
        let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
        view.cacheDisplay(in: view.bounds, to: rep)
        
        let image = NSImage(size: size)
        image.addRepresentation(rep)
        image.isTemplate = true
        return image
    }
}
