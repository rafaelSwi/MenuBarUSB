//
//  DonateContextMenuQRCode.swift
//  MenuBarUSB
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct DonateContextMenuQRCode: View {
    
    @Environment(\.openURL) var openURL
    
    @Binding var isBitcoin: Bool
    
    private func checkOnBlockchain(bitcoin: Bool) {
        let urlString: String
        if bitcoin {
            urlString = "https://www.blockchain.com/explorer/addresses/btc/\(Utils.Miscellaneous.btcAddress)"
        } else {
            urlString = "https://litecoinspace.org/address/\(Utils.Miscellaneous.ltcAddress)"
        }
        if let url = URL(string: urlString) {
            openURL(url)
        }
    }
    
    var currentAddress: String {
        return isBitcoin ? Utils.Miscellaneous.btcAddress : Utils.Miscellaneous.ltcAddress
    }
    
    var body: some View {
        Button { Utils.System.copyToClipboard(currentAddress) } label: {
            Label("copy_crypto_address", systemImage: "square.on.square")
        }

        Button { Utils.System.copyToClipboard(Utils.Miscellaneous.contactEmail) } label: {
            Label("copy_email", systemImage: "square.on.square")
        }

        Divider()

        Button { checkOnBlockchain(bitcoin: isBitcoin) } label: {
            Label("check_on_blockchain", systemImage: "globe")
        }
    }
}
