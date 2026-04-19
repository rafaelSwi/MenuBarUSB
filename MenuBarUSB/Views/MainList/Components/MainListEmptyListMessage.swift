//
//  MainListEmptyListMessage.swift
//  MenuBarUSB
//
//  Created by rafael on 19/04/26.
//

import SwiftUI

struct MainListEmptyListMessage: View {
    var body: some View {
        ScrollView {
            Text("no_devices_found")
                .foregroundStyle(.secondary)
                .padding(15)
        }
    }
}
