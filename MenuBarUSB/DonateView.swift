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
    @Environment(\.dismiss) var dismiss
    
    private let btcAddress = "bc1qvluxh224489mt6svp23kr0u8y2upn009pa546t"
    private let ltcAddress = "ltc1qz42uw4plam83f2sud2rckzewvdwm9vs4rfazl5"
    
    struct QRCodeView: View {
        let text: String
        
        var body: some View {
            if let image = generateQRCode(from: text) {
                Image(nsImage: image)
                    .interpolation(.none) // sem suavização
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
            
            // Escala o QR no nível do CoreImage (sem perder definição)
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
        
        VStack(spacing: 20) {
            
            Text(String(localized: "donate_description"))
                .font(.title2)
                .bold()
            
            HStack(spacing: 16) {
                Image(systemName: currentSymbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                    .foregroundColor(currentColor)
                
                QRCodeView(text: currentAddress)
                    .frame(width: 180, height: 180)
                    .padding(.horizontal, 30)
                
                Button(action: {
                    copyToClipboard(currentAddress)
                }) {
                    Label(String(localized: "copy"), systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                
                
            }
            
            Group {
                Text(isBitcoin ? String(localized: "bitcoin_on_chain_transfer") : String(localized: "litecoin_on_chain_transfer"))
                Text(currentAddress)
            }
            .font(.footnote)
            .textSelection(.enabled)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            
            VStack(spacing: 12) {
                
                Button(action: {
                    isBitcoin.toggle()
                }) {
                    Text(isBitcoin ? String(localized: "show_ltc_address") : String(localized: "show_btc_address"))
                }
                
                HStack {
                    Spacer()
                    Button(String(localized: "close_about_window")) {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(20)
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
