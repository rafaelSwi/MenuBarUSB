//
//  ManualTopic.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 28/11/25.
//

import Foundation

struct ManualTopic: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let markdownFileName: String
}
