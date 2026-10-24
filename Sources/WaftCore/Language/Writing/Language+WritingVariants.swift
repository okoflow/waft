extension Language {
    package var writingVariants: [WritingVariant] {
        switch self {
        case .chinese: [.simplified, .traditional]
        case .serbian: [.latin, .cyrillic]
        default: []
        }
    }
}
