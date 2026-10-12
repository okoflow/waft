import AppKit
import WaftCore

extension NSPasteboard {
    @discardableResult
    func writePrivately(_ item: NSPasteboardItem) -> Int {
        for type in PasteboardRestorePolicy.markerTypes {
            item.setData(Data(), forType: PasteboardType(type))
        }

        prepareForNewContents(with: .currentHostOnly)
        writeObjects([item])

        return changeCount
    }

    func writePrivately(_ text: String) {
        let item = NSPasteboardItem()
        item.setString(text, forType: .string)

        writePrivately(item)
    }
}
