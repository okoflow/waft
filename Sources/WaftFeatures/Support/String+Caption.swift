extension String {
    private static let captionSeparator = " · "
    private static let firstStrongIsolate = "\u{2068}"
    private static let popDirectionalIsolate = "\u{2069}"

    static func caption(joining parts: [String]) -> String {
        parts.map { firstStrongIsolate + $0 + popDirectionalIsolate }.joined(separator: captionSeparator)
    }
}
