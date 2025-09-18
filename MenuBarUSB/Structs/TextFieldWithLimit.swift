//
//  MaxLengthFormatter.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth Swierczynski on 31/08/25.
//

import SwiftUI
import AppKit

struct TextFieldWithLimit: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var maxLength: Int

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField(string: text)
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: TextFieldWithLimit

        init(_ parent: TextFieldWithLimit) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                if textField.stringValue.count > parent.maxLength {
                    textField.stringValue = String(textField.stringValue.prefix(parent.maxLength))
                }
                parent.text = textField.stringValue
            }
        }
    }
}
