struct AnthropicRequest: Encodable {
    struct OutputConfiguration: Encodable {
        let effort: String
    }

    enum CodingKeys: String, CodingKey {
        case model
        case maximumTokens = "max_tokens"
        case outputConfiguration = "output_config"
        case system
        case messages
    }

    let model: String
    let maximumTokens: Int
    let outputConfiguration = OutputConfiguration(effort: "low")
    let system: String
    let messages: [ChatMessage]
}
