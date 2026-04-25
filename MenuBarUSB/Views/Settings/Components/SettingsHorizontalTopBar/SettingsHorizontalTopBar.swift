//
//  SettingsHorizontalTopBar.swift
//  MenuBarUSB
//
//  Created by rafael on 17/04/26.
//

import SwiftUI

struct SettingsHorizontalTopBar: View {
    
    @Environment(\.openURL) var openURL
    
    @State private var checkingUpdate = false
    @State private var updateAvailable = false
    @State private var latestVersion: String = ""
    @State private var releaseURL: URL? = nil
    
    @Binding var currentWindow: AppWindow
    
    @AS(Key.hideUpdate) private var hideUpdate = false
    @AS(Key.hideDonate) private var hideDonate = false
    
    private var updateButtonLabel: String {
        
        if updateAvailable {
            return "\("download".localized) (v\(latestVersion))";
        }
        
        if checkingUpdate {
            return "checking"
        } else if latestVersion.isEmpty {
            return "check_for_updates"
        } else {
            return "updated"
        }
    }
    
    private func updateButtonAction() {
        
        if updateAvailable, let releaseURL {
            openURL(releaseURL)
            return
        }
        
        checkingUpdate = true
        updateAvailable = false
        latestVersion = ""
        releaseURL = nil
        
        guard
            let url = URL(
                string: Utils.Miscellaneous.latestRepoGithubApi)
        else {
            checkingUpdate = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            defer { checkingUpdate = false }
            guard let data = data, error == nil else { return }
            
            if let release = try? JSONDecoder().decode(GitHubRelease.self, from: data) {
                let latest = release.tag_name.replacingOccurrences(of: "v", with: "")
                latestVersion = latest
                releaseURL = URL(string: release.html_url)
                
                DispatchQueue.main.async {
                    updateAvailable = Utils.App.isVersion(Utils.App.appVersion, olderThan: latest)
                }
            }
        }.resume()
    }
    
    var body: some View {
        HStack {
            if !hideUpdate {
                Button(updateButtonLabel.localized) {
                    updateButtonAction()
                }
                .foregroundStyle(updateAvailable ? AssetColors.update : .primary)
                .contextMenu {
                    SettingsHorizontalTopBarContextMenuUpdate()
                }
            }
            
            if !hideDonate && !hideUpdate {
                Text("|")
                    .padding(.horizontal, 5)
                    .opacity(0.3)
            }
            
            if !hideDonate {
                
                Button("donate") {
                    currentWindow = .donate
                }
                .contextMenu {
                    SettingsHorizontalTopBarContextMenuDonate(currentWindow: $currentWindow)
                }
                
            }
        }
    }
}
