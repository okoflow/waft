extension String {
    func endingWithFullStop(in language: Language) -> String {
        guard let last, last.isLetter || last.isNumber else { return self }

        return self + language.fullStop
    }
}
