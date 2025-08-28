//
//  AboutView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {

            Link("MenuBarUSB", destination: URL(string: "https://github.com/rafaelSwi/MenuBarUSB")!)
                .font(.largeTitle)
                .fontWeight(.bold)


            Text(String(format: String(localized: "version"), appVersion))
                .font(.subheadline)
                .foregroundColor(.secondary)


            Text(String(localized: "created_by"))
                .multilineTextAlignment(.leading)
            
            Text(String(localized: "creator_location"))
                .multilineTextAlignment(.leading)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            
            Text(String(localized: "why_was_it_created"))
                .multilineTextAlignment(.leading)
                .font(.system(size: 9.2))
                .foregroundStyle(.secondary)
            
            Link(String(localized: "creator_github"), destination: URL(string: "https://github.com/rafaelSwi")!)
            
            
                

            Spacer()

            Button(String(localized: "close_about_window")) {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding(25)
        .frame(minWidth: 350, minHeight: 320)
        .background(.ultraThickMaterial) 
        .cornerRadius(15)
        .shadow(radius: 10)
    }
}
