//
//  LogsContextMenuRecentsOnly.swift
//  MenuBarUSB
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct LogsContextMenuRecentsOnly: View {
    
    @Binding var recentsAmount: Int
    
    private func addRecentsAmount() {
        if recentsAmount < 100 {
            recentsAmount += 10
        }
    }
    
    private func reduceRecentsAmount() {
        if recentsAmount > 10 {
            recentsAmount -= 10
        }
    }
    
    var body: some View {
        Button("increase_quantity", action: addRecentsAmount)
        Button("reduce_quantity", action: reduceRecentsAmount)
    }
}
