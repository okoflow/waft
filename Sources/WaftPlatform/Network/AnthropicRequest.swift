struct AnthropicRequest: Encodable {
    struct OutputConfig: Encodable {
        let effort: String
    }

    enum CodingKeys: String, CodingKey {
        case model
        case maximumTokens = "max_tokens"
        case outputConfig = "output_config"
        case system
        case messages
    }

    let model: String
    let maximumTokens: Int
    let outputConfig = OutputConfig(effort: "low")
    let system: String
    let messages: [ChatMessage]
}
