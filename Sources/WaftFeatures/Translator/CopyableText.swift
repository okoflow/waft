import AppKit
import SwiftUI

struct CopyableText: NSViewRepresentable {
    private static var attributes: [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = Metrics.translatorLineSpacing
        paragraph.baseWritingDirection = .natural

        return [
            .font: NSFont.systemFont(ofSize: Metrics.translatorTextSize),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraph,
        ]
    }

    let text: String
    let onCopy: (String) -> Void

    func makeNSView(context _: Context) -> NSScrollView {
        let textView = CopyingTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.isVerticallyResizable = true
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        textView.autoresizingMask = .width

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context _: Context) {
        guard let textView = scrollView.documentView as? CopyingTextView else { return }

        textView.onCopy = onCopy

        guard textView.string != text else { return }

        textView.textStorage?.setAttributedString(NSAttributedString(string: text, attributes: Self.attributes))
    }
}

private final class CopyingTextView: NSTextView {
    var onCopy: ((String) -> Void)?

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)

        guard !string.isEmpty else { return }

        if selectedRange().length == 0 {
            selectAll(nil)
        }

        onCopy?((string as NSString).substring(with: selectedRange()))
    }
}
