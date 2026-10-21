extension Character {
    var isLetterOrNumber: Bool {
        guard !isLetter else { return true }

        return isNumber
    }
}
