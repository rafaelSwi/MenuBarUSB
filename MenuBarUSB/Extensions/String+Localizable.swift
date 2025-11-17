//
//  String+Localizable.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth Swierczynski on 17/11/25.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
