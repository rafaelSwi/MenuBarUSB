//
//  SwiftUIView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth Swierczynski on 03/09/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct DonateView: View {
    @State private var isBitcoin = true
    
    @Binding var currentWindow: AppWindow
    
    private let btcAddress = "bc1qvluxh224489mt6svp23kr0u8y2upn009pa546t"
    private let ltcAddress = "ltc1qz42uw4plam83f2sud2rckzewvdwm9vs4rfazl5"
    
    struct QRCodeView: View {
        let text: String
        
        var body: some View {
            if let image = generateQRCode(from: text) {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.gray
            }
        }
        
        private func generateQRCode(from string: String) -> NSImage? {
            let context = CIContext()
            let filter = CIFilter.qrCodeGenerator()
            filter.message = Data(string.utf8)
            
            guard let outputImage = filter.outputImage else { return nil }
            
            let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
            
            if let cgimg = context.createCGImage(scaled, from: scaled.extent) {
                return NSImage(cgImage: cgimg, size: NSSize(width: 300, height: 300))
            }
            return nil
        }
    }
    
    var body: some View {
        let currentAddress = isBitcoin ? btcAddress : ltcAddress
        let currentSymbol = isBitcoin ? "bitcoinsign.circle.fill" : "l.circle.fill"
        let currentColor: Color = isBitcoin ? .orange : .gray
        
        VStack(spacing: 12) {
            
            Text(String(localized: "donate_description"))
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.bottom, 5)
            
            VStack(spacing: 15) {
                
                QRCodeView(text: currentAddress)
                    .frame(width: 200, height: 200)
                
                Button(action: {
                    copyToClipboard(currentAddress)
                }) {
                    let copyText = String(localized: "copy")
                    let coin = isBitcoin ? "BTC" : "LTC"
                    Label("\(copyText) (\(coin))", systemImage: "doc.on.doc")
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
                    
                    Text(String(localized: isBitcoin ? "bitcoin_on_chain_transfer" : "litecoin_on_chain_transfer"))
                        .font(.callout)
                        .bold()
                    
                }
                Group {
                    Text(currentAddress)
                    Text(String(format: NSLocalizedString("contact", comment: "EMAIL"), "contatorafaelswi@gmail.com"))
                }
                    .font(.footnote)
                    .textSelection(.enabled)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal)
            }
            
            VStack() {
                Button(action: {
                    isBitcoin.toggle()
                }) {
                    Text(isBitcoin ? String(localized: "show_ltc_address") : String(localized: "show_btc_address"))
                }
                .padding(.top, 10)
                Spacer()
                Button(action: {currentWindow = .settings}) {
                    Label(String(localized: "back"), systemImage: "arrow.uturn.backward")
                }
            }
        }
        .padding(10)
        .frame(minWidth: 465, minHeight: 530)
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
