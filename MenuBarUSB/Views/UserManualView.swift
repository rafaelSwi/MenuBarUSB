//
//  UserManualView.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/11/25.
//

import SwiftUI

struct UserManualView: View {
    
    let topics: [ManualTopic] = [
        ManualTopic(title: "Capabilities", markdownFileName: "capabilities"),
        ManualTopic(title: "Enumeration", markdownFileName: "enumeration"),
        ManualTopic(title: "Notification Handling", markdownFileName: "notification"),
    ]
    
    @State private var selectedTopic: ManualTopic?
    
    var body: some View {
        HStack(spacing: 20) {
            
            VStack(alignment: .leading, spacing: 8) {
                Text("manual")
                    .font(.title2)
                    .bold()
                    .padding(.bottom, 10)
                
                ScrollView {
                    ForEach(topics) { topic in
                        Button {
                            selectedTopic = topic
                        } label: {
                            Text(topic.title)
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(
                                    selectedTopic == topic
                                    ? Color(NSColor.systemBlue).opacity(0.25)
                                    : Color(NSColor.controlBackgroundColor)
                                )
                                .cornerRadius(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.black.opacity(0.4), lineWidth: 0.3)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
            }
            .frame(width: 220)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let topic = selectedTopic {
                        let markdown = Utils.Miscellaneous.loadTextFile(topic.markdownFileName)
                        Text(markdown)
                            .textSelection(.enabled)
                            .padding(.trailing, 20)
                            .font(.title3)
                    } else {
                        Text("selecione um topico")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
            }
            
        }
        .padding(10)
        .frame(minWidth: 700, minHeight: 580)
        .appBackground(true)
    }
}
