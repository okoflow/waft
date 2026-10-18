enum PromptTag: String {
    case transcript
    case instruction
    case instructions
    case text

    var open: String {
        "<\(rawValue)>"
    }

    var close: String {
        "</\(rawValue)>"
    }
}
