extension String {
    func endingWithFullStop(in language: Language) -> String {
        guard let last, last.isLetterOrNumber else { return self }

        return self + language.fullStop
    }
}
