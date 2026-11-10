import AppKit
import WaftCore

struct PasteboardSnapshot: Sendable {
    private struct Representation: Sendable {
        let type: String
        let data: Data
    }

    let plan: PasteboardRestorePolicy.Plan

    private let items: [[Representation]]
    private let isWaftItem: Bool

    static func take(from pasteboard: NSPasteboard) -> PasteboardSnapshot {
        guard let pasteboardItems = pasteboard.pasteboardItems else {
            return PasteboardSnapshot(plan: .skip(reason: .uncapturedItem), items: [], isWaftItem: false)
        }

        let sources = pasteboardItems.filter { !$0.types.isEmpty }
        let allTypes = sources.flatMap(\.types).map(\.rawValue)
        let savedTypes = sources.map { PasteboardRestorePolicy.typesToSave(from: $0.types.map(\.rawValue)) }

        let (contents, byteCount) = capturedContents(of: sources, saving: savedTypes)

        let items = zip(savedTypes, contents).map { types, contents in
            types.compactMap { type in contents[type].map { Representation(type: type, data: $0) } }
        }

        return PasteboardSnapshot(
            plan: PasteboardRestorePolicy.plan(
                currentTypes: allTypes,
                snapshotBytes: byteCount,
                hasUncapturedItem: items.contains(where: \.isEmpty),
            ),
            items: items,
            isWaftItem: allTypes.contains(PasteboardRestorePolicy.waftType),
        )
    }

    private static func capturedContents(
        of sources: [NSPasteboardItem],
        saving types: [[String]],
    ) -> (contents: [[String: Data]], byteCount: Int) {
        let limit = PasteboardRestorePolicy.maximumSnapshotBytes
        let requests = types.enumerated().flatMap { index, types in types.map { (index: index, type: $0) } }

        var contents = [[String: Data]](repeating: [:], count: sources.count)
        var byteCount = 0

        for request in requests.filter({ PasteboardRestorePolicy.isStandard($0.type) }) where byteCount <= limit {
            guard let data = sources[request.index].data(forType: NSPasteboard.PasteboardType(request.type)) else { continue }

            byteCount += data.count
            contents[request.index][request.type] = data
        }

        for request in requests.filter({ !PasteboardRestorePolicy.isStandard($0.type) }) where byteCount <= limit {
            guard let data = sources[request.index].data(forType: NSPasteboard.PasteboardType(request.type)) else { continue }
            guard byteCount + data.count <= limit else { break }

            byteCount += data.count
            contents[request.index][request.type] = data
        }

        return (contents, byteCount)
    }

    func restore(to pasteboard: NSPasteboard) {
        guard plan == .restore else { return }

        if isWaftItem {
            pasteboard.prepareForNewContents(with: .currentHostOnly)
        } else {
            pasteboard.clearContents()
        }

        let restored = items.map { representations in
            let item = NSPasteboardItem()

            for representation in representations {
                item.setData(representation.data, forType: NSPasteboard.PasteboardType(representation.type))
            }

            return item
        }

        pasteboard.writeObjects(restored)
    }
}
