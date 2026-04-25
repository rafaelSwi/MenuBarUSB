//
//  SettingsHorizontalTopBarContextMenuUpdate.swift
//  MenuBarUSB
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct SettingsHorizontalTopBarContextMenuUpdate: View {
    
    @Environment(\.openURL) var openURL
    
    private func openGithubPage() {
        if let url = URL(string: Utils.Miscellaneous.githubUrl) {
            openURL(url)
        }
    }
    
    @AS(Key.hideUpdate) private var hideUpdate = false
    
    var body: some View {
        Button {
            openGithubPage()
        } label: {
            Label("open_github_page", systemImage: "globe")
        }
        Divider()
        Button {
            hideUpdate = true
        } label: {
            Label("hide_button", systemImage: "eye.slash")
        }
    }
}
