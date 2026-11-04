import SwiftUI
import AppKit

public struct TypingBarView: View {
    @ObservedObject var engine = TypingBarEngine.shared
    @ObservedObject var wpmEngine = WPMEngine.shared

    public init() {}

    public var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 8) {
                // Target excerpt display (if excerpt was loaded/pasted)
                if let target = engine.targetExcerpt, !target.isEmpty {
                    targetExcerptView(target: target)
                }

                // Main input bar
                HStack(spacing: 12) {
                    // Typing input field
                    TypingInputField(
                        text: $engine.inputText,
                        isCompleted: engine.isCompleted,
                        placeholder: engine.targetExcerpt == nil ? "Type excerpt here, or press ⌘V to paste..." : "Type the excerpt above...",
                        onTextChange: { newText in
                            engine.onInputChanged(newText)
                        },
                        onSubmit: {
                            if engine.isCompleted {
                                engine.reset()
                            } else {
                                engine.finishSprint()
                            }
                        },
                        onEscape: {
                            TypingBarWindow.shared.hide()
                        },
                        onPasteExcerpt: {
                            engine.pasteExcerptFromClipboard()
                        }
                    )
                    .frame(minHeight: 28)

                    // Status & WPM Indicator Chip
                    statusChip
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: "121214"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(hex: "27272A"), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 8)
        }
        .frame(width: 600)
    }

    @ViewBuilder
    private func targetExcerptView(target: String) -> some View {
        let inputChars = Array(engine.inputText)
        let targetChars = Array(target)

        ScrollView(.vertical, showsIndicators: false) {
            HStack(alignment: .top, spacing: 0) {
                Text(buildHighlightedTarget(targetChars: targetChars, inputChars: inputChars))
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(hex: "18181B"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(hex: "27272A"), lineWidth: 0.5)
                    )
            )
        }
        .frame(maxHeight: 90)
    }

    private func buildHighlightedTarget(targetChars: [Character], inputChars: [Character]) -> AttributedString {
        var result = AttributedString()
        for i in 0..<targetChars.count {
            var letter = AttributedString(String(targetChars[i]))
            if i < inputChars.count {
                if inputChars[i] == targetChars[i] {
                    letter.foregroundColor = Color(hex: "10B981") // Solid Green
                } else {
                    letter.foregroundColor = Color(hex: "EF4444") // Solid Red
                    letter.underlineStyle = .single
                }
            } else if i == inputChars.count {
                letter.foregroundColor = Color(hex: "FFFFFF")
                letter.backgroundColor = Color(hex: "3F3F46")
            } else {
                letter.foregroundColor = Color(hex: "71717A") // Muted gray
            }
            result.append(letter)
        }
        return result
    }

    @ViewBuilder
    private var statusChip: some View {
        HStack(spacing: 6) {
            if engine.isCompleted {
                // Completed stats
                Text("\(engine.finalWPM) WPM")
                    .font(.system(size: 15, weight: .bold, design: .default).monospacedDigit())
                    .foregroundColor(wpmEngine.currentColor)

                Text("•")
                    .foregroundColor(Color(hex: "52525B"))

                Text(String(format: "%.1fs", engine.elapsedTime))
                    .font(.system(size: 13, weight: .medium, design: .default).monospacedDigit())
                    .foregroundColor(Color(hex: "A1A1AA"))

                if engine.targetExcerpt != nil {
                    Text("•")
                        .foregroundColor(Color(hex: "52525B"))
                    Text(String(format: "%.0f%%", engine.accuracy))
                        .font(.system(size: 13, weight: .medium, design: .default).monospacedDigit())
                        .foregroundColor(engine.accuracy >= 95 ? Color(hex: "10B981") : Color(hex: "F59E0B"))
                }

                Button(action: {
                    engine.reset()
                }) {
                    Text("Reset")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(hex: "27272A"))
                        .foregroundColor(Color(hex: "D4D4D8"))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            } else {
                // Active/idle live WPM
                Text("\(engine.currentWPM)")
                    .font(.system(size: 18, weight: .bold, design: .default).monospacedDigit())
                    .foregroundColor(wpmEngine.currentColor)

                Text("WPM")
                    .font(.system(size: 11, weight: .semibold, design: .default))
                    .foregroundColor(Color(hex: "71717A"))

                if engine.isRunning {
                    Text("•")
                        .foregroundColor(Color(hex: "3F3F46"))
                    Text(String(format: "%.0fs", engine.elapsedTime))
                        .font(.system(size: 12, weight: .regular, design: .default).monospacedDigit())
                        .foregroundColor(Color(hex: "A1A1AA"))
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(hex: "18181B"))
        )
    }
}

// Native AppKit NSTextField representable for seamless focus, Escape handling, and enter submit
struct TypingInputField: NSViewRepresentable {
    @Binding var text: String
    var isCompleted: Bool
    var placeholder: String
    var onTextChange: (String) -> Void
    var onSubmit: () -> Void
    var onEscape: () -> Void
    var onPasteExcerpt: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSTextField {
        let textField = CustomTextField()
        textField.isBordered = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.font = NSFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        textField.textColor = NSColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1.0)
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        textField.onEscape = onEscape
        textField.onSubmit = onSubmit
        textField.onPasteExcerpt = onPasteExcerpt

        DispatchQueue.main.async {
            textField.window?.makeFirstResponder(textField)
        }

        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        nsView.placeholderString = placeholder
        nsView.isEditable = !isCompleted

        if !isCompleted && nsView.window?.firstResponder != nsView.currentEditor() {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: TypingInputField

        init(_ parent: TypingInputField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            parent.text = textField.stringValue
            parent.onTextChange(textField.stringValue)
        }
    }
}

class CustomTextField: NSTextField {
    var onEscape: (() -> Void)?
    var onSubmit: (() -> Void)?
    var onPasteExcerpt: (() -> Void)?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Cmd+V when field is empty: load excerpt from clipboard
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "v" {
            if stringValue.isEmpty {
                onPasteExcerpt?()
                return true
            }
        }
        return super.performKeyEquivalent(with: event)
    }

    override func cancelOperation(_ sender: Any?) {
        onEscape?()
    }

    override func textDidEndEditing(_ notification: Notification) {
        super.textDidEndEditing(notification)
        if let reason = notification.userInfo?["NSTextMovement"] as? Int, reason == NSReturnTextMovement {
            onSubmit?()
        }
    }
}
