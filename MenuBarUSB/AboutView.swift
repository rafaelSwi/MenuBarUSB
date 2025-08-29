//
//  AboutView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/08/25.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var updateAvailable = false
    @State private var latestVersion: String = ""
    @State private var releaseURL: URL? = nil
    @State private var checkingUpdate = false
    
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
            
            Link(String(localized: "creator_github"), destination: URL(string: "https://github.com/rafaelSwi")!)
            
            Button {
                checkForUpdate()
            } label: {
                if checkingUpdate {
                    ProgressView()
                } else {
                    Text(String(localized: "check_for_updates"))
                }
            }
            .buttonStyle(.bordered)
            
            if updateAvailable, let releaseURL {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(String(localized: "new_version_available")): \(latestVersion)")

                    Link(String(localized: "open_download_page"), destination: releaseURL)
                        .buttonStyle(.borderedProminent)
                }
            } else if !checkingUpdate && !latestVersion.isEmpty {
                Text(String(localized: "up_to_date"))

            }
            
            Spacer()
            
            Button(String(localized: "close_about_window")) {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding(25)
        .frame(minWidth: 350, minHeight: 380)
        .background(.ultraThickMaterial)
        .cornerRadius(15)
        .shadow(radius: 10)
    }
    
    private func checkForUpdate() {
        checkingUpdate = true
        updateAvailable = false
        latestVersion = ""
        releaseURL = nil
        
        guard let url = URL(string: "https://api.github.com/repos/rafaelSwi/MenuBarUSB/releases/latest") else {
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
                
                if isVersion(appVersion, olderThan: latest) {
                    DispatchQueue.main.async {
                        updateAvailable = true
                    }
                } else {
                    DispatchQueue.main.async {
                        updateAvailable = false
                    }
                }
            }
        }.resume()
    }
    
    private func isVersion(_ v1: String, olderThan v2: String) -> Bool {
        let v1Components = v1.split(separator: ".").compactMap { Int($0) }
        let v2Components = v2.split(separator: ".").compactMap { Int($0) }
        
        for (a, b) in zip(v1Components, v2Components) {
            if a < b { return true }
            if a > b { return false }
        }
        return v1Components.count < v2Components.count
    }
}

struct GitHubRelease: Codable {
    let tag_name: String
    let html_url: String
}
