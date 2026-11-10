extension String {
    func withOuterWhitespace(of original: String) -> String {
        let leading = original.prefix(while: \.isWhitespace)
        let trailing = original.dropFirst(leading.count).reversed().prefix(while: \.isWhitespace).reversed()

        return leading + self + String(trailing)
    }
}
