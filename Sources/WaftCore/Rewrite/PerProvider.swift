package struct PerProvider<Value> {
    package var claude: Value
    package var openAI: Value

    package init(claude: Value, openAI: Value) {
        self.claude = claude
        self.openAI = openAI
    }

    package init(_ value: (CloudProvider) -> Value) {
        self.init(claude: value(.claude), openAI: value(.openAI))
    }

    package subscript(_ provider: CloudProvider) -> Value {
        get {
            switch provider {
            case .claude: claude
            case .openAI: openAI
            }
        }
        set {
            switch provider {
            case .claude: claude = newValue
            case .openAI: openAI = newValue
            }
        }
    }
}

extension PerProvider: Sendable where Value: Sendable {}

extension PerProvider: Equatable where Value: Equatable {}

extension PerProvider: Codable where Value: Codable {}
