package enum PasteboardRestorePolicy {
    package enum Plan: Equatable, Sendable {
        case restore
        case skip(reason: SkipReason)
    }

    package enum SkipReason: String, Sendable {
        case privateItem
        case tooLarge
        case uncapturedItem
    }

    package static let maximumSnapshotBytes = 5 * 1024 * 1024
    package static let waftType = "com.okoflow.waft.transcript"
    package static let markerTypes = [transientType, concealedType, waftType]

    static let concealedType = "org.nspasteboard.ConcealedType"
    static let transientType = "org.nspasteboard.TransientType"

    private static let standardTypes: Set<String> = [
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
        let kept = types.filter { !$0.lowercased().contains("promise") }
        guard kept.contains("public.png") else { return kept }

        return kept.filter { $0 != "public.tiff" }
    }

    package static func isStandard(_ type: String) -> Bool {
        standardTypes.contains(type)
    }

    package static func plan(currentTypes: [String], snapshotBytes: Int, hasUncapturedItem: Bool) -> Plan {
        let isWaftItem = currentTypes.contains(waftType)
        let isPrivateItem = [concealedType, transientType].contains(where: currentTypes.contains)

        if isPrivateItem, !isWaftItem {
            return .skip(reason: .privateItem)
        }

        if snapshotBytes > maximumSnapshotBytes {
            return .skip(reason: .tooLarge)
        }

        if hasUncapturedItem {
            return .skip(reason: .uncapturedItem)
        }

        return .restore
    }
}
