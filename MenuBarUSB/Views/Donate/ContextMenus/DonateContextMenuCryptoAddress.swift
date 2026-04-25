//
//  DonateContextMenuCryptoAddress.swift
//  MenuBarUSB
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct DonateContextMenuCryptoAddress: View {
    
    var currentAddress: String
    
    var body: some View {
        Button("copy") {
            Utils.System.copyToClipboard(currentAddress)
        }
    }
}
