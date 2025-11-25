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
    
    private func checkOnBlockchain(bitcoin: Bool) {
        let urlString: String
        if bitcoin {
            urlString = "https://www.blockchain.com/explorer/addresses/btc/\(btcAddress)"
        } else {
            urlString = "https://litecoinspace.org/address/\(ltcAddress)"
        }
        if let url = URL(string: urlString) {
            openURL(url)
        }
    }

    var body: some View {
        let currentAddress = isBitcoin ? btcAddress : ltcAddress
        let currentSymbol = isBitcoin ? "bitcoinsign.circle.fill" : "l.circle.fill"
        let currentColor: Color = isBitcoin ? .orange : Color("LTC")
        let email = "contatorafaelswi@gmail.com"

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
                        Button { Utils.System.copyToClipboard(currentAddress) } label: {
                            Label("copy_crypto_address", systemImage: "square.on.square")
                        }

                        Button { Utils.System.copyToClipboard(email) } label: {
                            Label("copy_email", systemImage: "square.on.square")
                        }

                        Divider()

                        Button { checkOnBlockchain(bitcoin: isBitcoin) } label: {
                            Label("check_on_blockchain", systemImage: "globe")
                        }
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
                            Button { Utils.System.copyToClipboard(currentAddress) } label: {
                                Label("copy", systemImage: "square.on.square")
                            }
                        }
                    Text(String(format: NSLocalizedString("contact", comment: "EMAIL"), email))
                        .contextMenu {
                            Button { Utils.System.copyToClipboard(email) } label: {
                                Label("copy_email", systemImage: "square.on.square")
                            }
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
