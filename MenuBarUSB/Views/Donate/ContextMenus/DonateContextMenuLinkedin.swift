//
//  DonateContextMenuLinkedin.swift
//  MenuBarUSB
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct DonateContextMenuLinkedin: View {
    
    @Environment(\.openURL) var openURL
    
    private func openLinkedinProfile() {
        if let url = URL(string: Utils.Miscellaneous.linkedinUrl) {
            openURL(url)
        }
    }
    
    var body: some View {
        Button("copy_profile_url") {
            Utils.System.copyToClipboard(Utils.Miscellaneous.linkedinUrl)
        }
        Button("open_linkedin_profile") {
            openLinkedinProfile()
        }
    }
}
