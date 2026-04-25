//
//  DonateContextMenuEmail.swift
//  MenuBarUSB
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct DonateContextMenuEmail: View {
    var body: some View {
        Button("copy_email") {
            Utils.System.copyToClipboard(Utils.Miscellaneous.contactEmail)
        }
    }
}
