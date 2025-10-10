//
//  CustomTextField.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth Swierczynski on 31/08/25.
//

import AppKit
import SwiftUI

struct CustomTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var maxLength: Int
    @Binding var isFocused: Bool

    func makeNSView(context: Context) -> NSView {
        let container = NSView()

        let textField = NSTextField(string: text)
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        textField.focusRingType = .default
        textField.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textField)

        let emojiButton = NSButton(title: "😃", target: context.coordinator, action: #selector(Coordinator.toggleEmojiPicker))
        emojiButton.bezelStyle = .rounded
        emojiButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(emojiButton)

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textField.topAnchor.constraint(equalTo: container.topAnchor),
            textField.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            emojiButton.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 4),
            emojiButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            emojiButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
        ])

        context.coordinator.textField = textField
        context.coordinator.emojiButton = emojiButton

        return container
    }

    func updateNSView(_: NSView, context: Context) {
        if let textField = context.coordinator.textField {
            textField.stringValue = text
            if isFocused, let window = textField.window {
                window.makeFirstResponder(textField)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CustomTextField
        weak var textField: NSTextField?
        weak var emojiButton: NSButton?
        var emojiPopover: NSPopover?

        init(_ parent: CustomTextField) {
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

        @objc func toggleEmojiPicker() {
            if emojiPopover == nil {
                let popover = NSPopover()
                popover.contentSize = NSSize(width: 200, height: 200)
                popover.behavior = .transient
                popover.contentViewController = NSHostingController(rootView: EmojiPickerView { emoji in
                    if let textField = self.textField {
                        let current = textField.stringValue
                        let newText = current + emoji
                        textField.stringValue = String(newText.prefix(self.parent.maxLength))
                        self.parent.text = textField.stringValue
                    }
                    popover.performClose(nil)
                })
                emojiPopover = popover
            }

            if let button = emojiButton, let popover = emojiPopover {
                if popover.isShown {
                    popover.performClose(nil)
                } else {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
                }
            }
        }
    }
}

private struct EmojiPickerView: View {
    var onSelect: (String) -> Void
    let emojis = [
        "💻", "🖥️", "🖱️", "⌨️", "🖲️", "💾", "💿", "📀", "📱", "📲",
        "📡", "🔌", "🔋", "⚡", "🛠️", "🧰", "🖧", "🌐", "🕹️", "🛡️",
        "📶", "🔗", "💡", "📂", "🗄️", "🧮", "🤖", "🧬", "🛰️", "🔭",
        "🎛️", "🎚️", "⚙️", "🪛", "🔧", "🔒", "🔑", "🪙", "💳", "🧑‍💻",
        "👨‍💻", "👩‍💻", "🧑‍🔧", "👨‍🔧", "👩‍🔧", "📷", "📸", "🎥", "📹", "🔦",
        "💿", "📼", "🎞️", "🎛️", "🎚️", "🧩", "🧪", "📡", "📶", "🖲️",
        "🛎️", "⏱️", "⌚", "📟", "📠", "🖨️", "🧾", "💼", "📋", "📁",
        "🗂️", "🗃️", "🧭", "🪐", "🛸", "🚀", "🛳️", "🛰️", "🪝", "⚙️",
        "🪙", "🧱", "🪛", "🔩", "⚡", "🔌", "🔋", "💻", "🖥️", "⌨️",
        "🖱️", "🖲️", "🧑‍💻", "👨‍💻", "👩‍💻", "🤖", "🧬", "🛰️", "🌐", "📶",
        "📡", "🔗", "🛡️", "💡", "🔒", "🔑", "📂", "🗄️", "🧰", "🛠️",
        "🧩", "🎛️", "🎚️", "🎮", "🕹️", "📷", "📹", "📸", "🎥", "🖨️",
        "🧾", "💿", "📀", "📼", "🎞️", "🪙", "💳", "🔭", "🧮", "🧭",
        "🪐", "🛸", "🚀", "🛳️", "⚙️", "🧱", "🪛", "🔩", "🪝", "⚡",
        "🔌", "🔋", "🖧", "🖲️", "🛎️", "⏱️", "⌚", "📟", "📠", "🖥️",
        "⚪", "⚫", "🟣", "🟠", "🟡", "🔷", "🔘", "🔳", "🔲",
    ]
    let columns = [GridItem(.adaptive(minimum: 40))]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(emojis, id: \.self) { emoji in
                    Text(emoji)
                        .font(.system(size: 32))
                        .onTapGesture { onSelect(emoji) }
                }
            }
            .padding()
        }
        .frame(width: 200, height: 200)
    }
}
