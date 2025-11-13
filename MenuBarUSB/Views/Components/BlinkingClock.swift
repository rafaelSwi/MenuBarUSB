//
//  BlinkingClock.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 13/11/25.
//

import SwiftUI

struct BlinkingClock: View {
    @State private var showColon = true
    @State private var time = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(timeFormatted)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(.gray)
            .onReceive(timer) { _ in
                time = Date()
                showColon.toggle()
            }
    }

    private var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = showColon ? "HH:mm" : "HH mm"
        return formatter.string(from: time)
    }
}
