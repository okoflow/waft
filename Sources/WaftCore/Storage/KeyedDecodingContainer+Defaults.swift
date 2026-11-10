extension KeyedDecodingContainer {
    private struct ValidElement<Value: Decodable>: Decodable {
        let value: Value?

        init(from decoder: any Decoder) {
            let value = try? Value(from: decoder)

            self.value = value
        }
    }

    package func decodeValidElements<Element: Decodable>(_ key: Key) -> [Element] {
        let elements: [ValidElement<Element>] = decode(key, default: [])

        return elements.compactMap(\.value)
    }

    func decodeValidValues<Value: Decodable>(_ key: Key) -> [String: Value] {
        let values: [String: ValidElement<Value>] = decode(key, default: [:])

        return values.compactMapValues(\.value)
    }

    func decodeEachProvider<Value: Decodable>(_ key: Key, default fallback: PerProvider<Value>) -> PerProvider<Value> {
        guard let stored = try? nestedContainer(keyedBy: PerProvider<Value>.CodingKeys.self, forKey: key) else {
            return fallback
        }

        return PerProvider(
            claude: stored.decode(.claude, default: fallback.claude),
            openAI: stored.decode(.openAI, default: fallback.openAI),
        )
    }

    func decode<Value: Decodable>(_ key: Key, default fallback: Value) -> Value {
        guard let value: Value = decodeIfValid(key) else { return fallback }

        return value
    }

    func decodeIfValid<Value: Decodable>(_ key: Key) -> Value? {
        guard let value = try? decodeIfPresent(Value.self, forKey: key) else { return nil }

        return value
    }
}
