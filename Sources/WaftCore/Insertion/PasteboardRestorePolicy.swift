package enum PasteboardRestorePolicy {
    package enum Plan: Equatable, Sendable {
        case restore
        case skip(reason: SkipReason)
    }

    package enum SkipReason: String, Sendable {
        case privateItem
        case tooLarge
    }

    package static let maximumSnapshotBytes = 5 * 1024 * 1024
    package static let waftType = "com.okoflow.waft.transcript"
    package static let markerTypes = [transientType, concealedType, waftType]

    static let concealedType = "org.nspasteboard.ConcealedType"
    static let transientType = "org.nspasteboard.TransientType"

    private static let restorableTypes: Set<String> = [
        "public.utf8-plain-text",
        "public.utf16-plain-text",
        "public.utf16-external-plain-text",
        "NSStringPboardType",
        "public.rtf",
        "public.html",
        "public.png",
        "public.jpeg",
        "public.tiff",
        "com.adobe.pdf",
        "public.file-url",
        "public.url",
        "public.url-name",
        concealedType,
        transientType,
        waftType,
    ]

    package static func typesToSave(from types: [String]) -> [String] {
        guard types.contains("public.png") else { return types.filter(restorableTypes.contains) }

        let saved = restorableTypes.subtracting(["public.tiff"])

        return types.filter(saved.contains)
    }

    package static func plan(currentTypes: [String], snapshotBytes: Int) -> Plan {
        let isWaftItem = currentTypes.contains(waftType)
        let isPrivateItem = [concealedType, transientType].contains(where: currentTypes.contains)

        if isPrivateItem, !isWaftItem {
            return .skip(reason: .privateItem)
        }

        if snapshotBytes > maximumSnapshotBytes {
            return .skip(reason: .tooLarge)
        }

        return .restore
    }
}
