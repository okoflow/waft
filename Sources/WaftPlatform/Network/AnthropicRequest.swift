struct AnthropicRequest: Encodable {
    struct Thinking: Encodable {
        let type: String
    }

    enum CodingKeys: String, CodingKey {
        case model
        case maximumTokens = "max_tokens"
        case thinking
        case system
        case messages
    }

    let model: String
    let maximumTokens: Int
    let thinking = Thinking(type: "disabled")
    let system: String
    let messages: [ChatMessage]
}
