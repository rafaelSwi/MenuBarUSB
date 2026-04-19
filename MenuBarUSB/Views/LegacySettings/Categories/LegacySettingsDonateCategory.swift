//
//  LegacySettingsDonateCategory.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct LegacySettingsDonateCategory: View {
    
    @Environment(\.openURL) var openURL
    
    @State private var isBitcoin = true
    
    private func openLinkedinProfile() {
        if let url = URL(string: Utils.Miscellaneous.linkedinUrl) {
            openURL(url)
        }
    }
    
    var body: some View {
        let currentAddress = isBitcoin ? Utils.Miscellaneous.btcAddress : Utils.Miscellaneous.ltcAddress
        let currentSymbol = isBitcoin ? "bitcoinsign.circle.fill" : "l.circle.fill"
        let currentColor: Color = isBitcoin ? .orange : AssetColors.ltcCoin
        let email = Utils.Miscellaneous.contactEmail

        HStack(spacing: 20) {
            Utils.Miscellaneous.QRCodeView(text: currentAddress)
                .frame(width: 230, height: 230)
                .padding()
                .contextMenu {
                    Button { Utils.System.copyToClipboard(currentAddress) } label: {
                        Label("copy_crypto_address", systemImage: "square.on.square")
                    }

                    Button { Utils.System.copyToClipboard(email) } label: {
                        Label("copy_email", systemImage: "square.on.square")
                    }
                }

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: currentSymbol)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(currentColor)

                    Text(isBitcoin ? "bitcoin_on_chain_transfer" : "litecoin_on_chain_transfer")
                        .font(.headline)
                        .bold()
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(currentAddress)
                        .font(.subheadline)
                        .contextMenu {
                            Button { Utils.System.copyToClipboard(currentAddress) } label: {
                                Label("copy", systemImage: "square.on.square")
                            }
                        }

                    Text(String(format: NSLocalizedString("contact", comment: "EMAIL"), email))
                        .font(.subheadline)
                        .contextMenu {
                            Button { Utils.System.copyToClipboard(email) } label: {
                                Label("copy_email", systemImage: "square.on.square")
                            }
                        }
                }
                
                Text(String(format: NSLocalizedString("linkedin_profile", comment: "LINKEDIN"), Utils.Miscellaneous.linkedinProfile))
                    .font(.subheadline)
                    .contextMenu {
                        Button("copy_profile_url") {
                            Utils.System.copyToClipboard(Utils.Miscellaneous.linkedinUrl)
                        }
                        Button("open_linkedin_profile") {
                            openLinkedinProfile()
                        }
                    }

                Button(action: { isBitcoin.toggle() }) {
                    Text(isBitcoin ? "show_ltc_address" : "show_btc_address")
                }
                .padding(.top, 4)
            }
            .padding(.vertical)
        }
        .padding(.horizontal)
    }
}
