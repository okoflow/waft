import ApplicationServices
import WaftCore

struct AccessibilityElement: FocusedElement, @unchecked Sendable {
    private static let messagingTimeout: Float = 0.1

    private let element: AXUIElement

    var isSecureTextField: Bool {
        string(kAXSubroleAttribute) == kAXSecureTextFieldSubrole
    }

    var selectedText: String? {
        string(kAXSelectedTextAttribute).flatMap { $0.isEmpty ? nil : $0 }
    }

    var hasEmptySelection: Bool {
        guard let selection = selectedRange() else { return false }

        return selection.length == 0
    }

    var characterBeforeCaret: Character? {
        guard let selection = selectedRange(), selection.location > 0 else { return nil }

        var previous = CFRange(location: selection.location - 1, length: 1)
        guard let parameter = AXValueCreate(.cfRange, &previous) else { return nil }

        var value: CFTypeRef?
        let status = AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXStringForRangeParameterizedAttribute as CFString,
            parameter,
            &value,
        )

        guard status == .success, let character = (value as? String)?.first, character != "\u{FFFD}" else { return nil }

        return character
    }

    private var window: AXUIElement? {
        Self.attribute(kAXWindowAttribute, of: element)
    }

    private init(_ element: AXUIElement) {
        AXUIElementSetMessagingTimeout(element, Self.messagingTimeout)
        self.element = element
    }

    static func focusedElement() -> AccessibilityElement? {
        let systemWide = AXUIElementCreateSystemWide()
        AXUIElementSetMessagingTimeout(systemWide, messagingTimeout)

        return attribute(kAXFocusedUIElementAttribute, of: systemWide).map(AccessibilityElement.init)
    }

    private static func value(_ name: String, of element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }

        return value
    }

    private static func attribute(_ name: String, of element: AXUIElement) -> AXUIElement? {
        guard let value = value(name, of: element), CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }

        return unsafeDowncast(value, to: AXUIElement.self)
    }

    func isDifferent(from other: any FocusedElement) -> Bool {
        guard let other = other as? AccessibilityElement else { return false }

        if CFEqual(element, other.element) {
            return false
        }

        guard let role = string(kAXRoleAttribute),
              role == other.string(kAXRoleAttribute),
              let window,
              let otherWindow = other.window,
              CFEqual(window, otherWindow)
        else { return true }

        return false
    }

    private func string(_ name: String) -> String? {
        Self.value(name, of: element) as? String
    }

    private func selectedRange() -> CFRange? {
        guard let value = Self.value(kAXSelectedTextRangeAttribute, of: element), CFGetTypeID(value) == AXValueGetTypeID()
        else { return nil }

        var range = CFRange()
        guard AXValueGetValue(unsafeDowncast(value, to: AXValue.self), .cfRange, &range) else { return nil }

        return range
    }
}
