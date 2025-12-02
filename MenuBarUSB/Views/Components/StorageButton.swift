//
//  StorageButton.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth Swierczynski on 01/12/25.
//

import SwiftUI

struct StorageButton: View {
    let labelKey: String
    let icon: String
    let count: Int
    let action: () -> Void

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 13)
            Button(labelKey.localized) {
                action()
            }

            Spacer()

            Image(systemName: icon)
                .font(.system(size: 9))

            Text("\(count)")
                .font(.subheadline)
        }
        .opacity(count > 0 ? 1.0 : 0.4)
    }
}
