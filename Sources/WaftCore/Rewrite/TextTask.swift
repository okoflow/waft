package enum TextTask: Equatable, Sendable {
    case fix
    case translate(from: Language?, into: Language)
}
