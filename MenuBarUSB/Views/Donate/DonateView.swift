//
//  DonateView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth Swierczynski on 03/09/25.
//

import CoreImage.CIFilterBuiltins
import SwiftUI

struct DonateView: View {
    @Environment(\.openURL) var openURL

    @State private var isBitcoin = true

    @Binding var currentWindow: AppWindow

    let btcAddress = Utils.Miscellaneous.btcAddress
    let ltcAddress = Utils.Miscellaneous.ltcAddress
    
    var currentAddress: String {
        return isBitcoin ? btcAddress : ltcAddress
    }
    
    var email: String {
        return Utils.Miscellaneous.contactEmail
    }
    
    var linkedin: String {
        return Utils.Miscellaneous.linkedinProfile
    }
    
    var currentSymbol: String {
        return isBitcoin ? "bitcoinsign.circle.fill" : "l.circle.fill"
    }
    
    var currentColor: Color {
        return isBitcoin ? .orange : AssetColors.ltcCoin
    }

    var body: some View {

        VStack(spacing: 12) {
            Text("donate_description")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.bottom, 5)

            VStack(spacing: 15) {
                Utils.Miscellaneous.QRCodeView(text: currentAddress)
                    .frame(width: 250, height: 250)
                    .contextMenu {
                        DonateContextMenuQRCode(isBitcoin: $isBitcoin)
                    }

                Button(action: { Utils.System.copyToClipboard(currentAddress) }) {
                    let copyText = "copy".localized
                    let coin = isBitcoin ? "BTC" : "LTC"
                    Label("\(copyText) (\(coin))", systemImage: "square.on.square")
                }
                .padding(.horizontal, 40)
            }

            Group {
                HStack {
                    Image(systemName: currentSymbol)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 17, height: 17)
                        .foregroundColor(currentColor)

                    Text(isBitcoin ? "bitcoin_on_chain_transfer" : "litecoin_on_chain_transfer")
                        .font(.callout)
                        .bold()
                }
                Group {
                    Text(currentAddress)
                        .contextMenu {
                            DonateContextMenuCryptoAddress(currentAddress: currentAddress)
                        }
                    Text(String(format: NSLocalizedString("contact", comment: "EMAIL"), email))
                        .contextMenu {
                            DonateContextMenuEmail()
                        }
                    Text(String(format: NSLocalizedString("linkedin_profile", comment: "LINKEDIN"), linkedin))
                        .contextMenu {
                            DonateContextMenuLinkedin()
                        }
                }
                .font(.footnote)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal)
            }

            VStack {
                Button(action: { isBitcoin.toggle() }) {
                    Text(isBitcoin ? "show_ltc_address" : "show_btc_address")
                }
                .padding(.top, 10)

                Spacer()

                HStack {
                    Spacer()
                    Button(action: { currentWindow = .settings }) {
                        Label("back", systemImage: "arrow.uturn.backward")
                    }
                }
            }
        }
        .padding(10)
        .frame(minWidth: WindowWidth.value, minHeight: 600)
    }
}
