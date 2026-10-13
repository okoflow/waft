struct ChatCompletionsRequest: Encodable {
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maximumTokens = "max_tokens"
        case stream
    }

    let model: String
    let messages: [ChatMessage]
    let temperature = 0.2
    let maximumTokens: Int
    let stream = false
}
