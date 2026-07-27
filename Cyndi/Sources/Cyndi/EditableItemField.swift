import SwiftUI
import AppKit

struct EditableItemField: NSViewRepresentable {
    @Binding var text: String
    var isFocused: Bool
    var font: NSFont
    var textColor: NSColor
    var strikethrough: Bool
    var placeholder: String
    var placeholderColor: NSColor

    var onFocus: () -> Void = {}
    var onSubmit: () -> Void = {}
    var onMoveUp: () -> Void = {}
    var onMoveDown: () -> Void = {}
    var onDeleteWhenEmpty: () -> Void = {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.delegate = context.coordinator
        field.lineBreakMode = .byTruncatingTail
        field.cell?.usesSingleLineMode = true
        field.cell?.wraps = false
        field.cell?.isScrollable = true
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return field
    }

    func updateNSView(_ field: NSTextField, context: Context) {
        context.coordinator.parent = self

        field.font = font
        field.placeholderAttributedString = NSAttributedString(
            string: placeholder,
            attributes: [.font: font, .foregroundColor: placeholderColor])

        if field.currentEditor() == nil {
            field.attributedStringValue = Self.styled(
                text, font: font, color: textColor, strikethrough: strikethrough)
        }

        if isFocused {
            DispatchQueue.main.async {
                guard let window = field.window, field.currentEditor() == nil else { return }
                window.makeFirstResponder(field)
            }
        }
    }

    private static func styled(
        _ string: String, font: NSFont, color: NSColor, strikethrough: Bool
    ) -> NSAttributedString {
        var attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        if strikethrough {
            attrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            attrs[.strikethroughColor] = color
        }
        return NSAttributedString(string: string, attributes: attrs)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: EditableItemField

        init(_ parent: EditableItemField) { self.parent = parent }

        func controlTextDidBeginEditing(_ obj: Notification) {
            parent.onFocus()
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView,
                     doCommandBy selector: Selector) -> Bool {
            switch selector {
            case #selector(NSResponder.insertNewline(_:)):
                parent.onSubmit()
                return true
            case #selector(NSResponder.moveUp(_:)):
                parent.onMoveUp()
                return true
            case #selector(NSResponder.moveDown(_:)):
                parent.onMoveDown()
                return true
            case #selector(NSResponder.deleteBackward(_:)):
                if textView.string.isEmpty {
                    parent.onDeleteWhenEmpty()
                    return true
                }
                return false
            default:
                return false
            }
        }
    }
}
