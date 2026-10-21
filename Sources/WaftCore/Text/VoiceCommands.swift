enum VoiceCommands {
    private struct Command {
        let words: [String]
        let isParagraph: Bool
    }

    private static let lines: [Language: [String]] = [
        .chinese: ["换行"],
        .czech: ["nový řádek"],
        .danish: ["ny linje"],
        .dutch: ["nieuwe regel"],
        .english: ["new line", "newline", "next line"],
        .finnish: ["uusi rivi"],
        .french: ["nouvelle ligne", "à la ligne"],
        .german: ["neue zeile", "nächste zeile"],
        .italian: ["nuova riga", "a capo"],
        .japanese: ["改行"],
        .korean: ["줄 바꿈", "줄바꿈"],
        .norwegian: ["ny linje"],
        .polish: ["nowa linia", "nowy wiersz"],
        .portuguese: ["nova linha"],
        .russian: ["новая строка", "с новой строки"],
        .spanish: ["nueva línea"],
        .swedish: ["ny rad"],
        .turkish: ["yeni satır"],
        .ukrainian: ["новий рядок", "з нового рядка"],
    ]

    private static let paragraphs: [Language: [String]] = [
        .chinese: ["新段落"],
        .czech: ["nový odstavec"],
        .danish: ["nyt afsnit"],
        .dutch: ["nieuwe alinea"],
        .english: ["new paragraph", "next paragraph"],
        .finnish: ["uusi kappale"],
        .french: ["nouveau paragraphe"],
        .german: ["neuer absatz"],
        .italian: ["nuovo paragrafo"],
        .japanese: ["新しい段落"],
        .korean: ["새 문단", "새 단락"],
        .norwegian: ["nytt avsnitt"],
        .polish: ["nowy akapit"],
        .portuguese: ["novo parágrafo"],
        .russian: ["новый абзац", "с нового абзаца"],
        .spanish: ["nuevo párrafo"],
        .swedish: ["nytt stycke"],
        .turkish: ["yeni paragraf"],
        .ukrainian: ["новий абзац", "з нового абзацу"],
    ]

    private static let joiningMarks: Set<Character> = [",", "，", "、", ";", "；", ":", "：", "-", "–", "—"]

    static func apply(_ text: String, language: Language) -> String {
        let commands = commands(for: language)
        guard !commands.isEmpty else { return text }

        let segments = TextSegment.split(text)
        var result = ""
        var index = 0
        var capitalizesNext = false

        while index < segments.count {
            let segment = segments[index]

            if segment.isWord, let (command, end) = match(commands, at: index, in: segments, language: language) {
                result = endingLine(result, language: language, isParagraph: command.isParagraph)
                result += command.isParagraph ? "\n\n" : "\n"
                index = end + 1
                capitalizesNext = true
            } else if capitalizesNext, !segment.isWord {
                result += String(segment.text.filter { !$0.isPauseMark && $0 != " " })
                index += 1
            } else {
                let capitalizes = capitalizesNext && language.hasLetterCase
                result += capitalizes ? segment.text.capitalizingFirstLetter(in: language) : segment.text
                capitalizesNext = false
                index += 1
            }
        }

        return result
    }

    private static func commands(for language: Language) -> [Command] {
        let commands = [(lines, false), (paragraphs, true)].flatMap { phrases, isParagraph in
            phrases[language, default: []]
                .map { Command(words: TextSegment.words(of: $0, in: language), isParagraph: isParagraph) }
        }

        return commands.sorted { $0.words.count > $1.words.count }
    }

    private static func match(
        _ commands: [Command],
        at start: Int,
        in segments: [TextSegment],
        language: Language,
    ) -> (Command, Int)? {
        guard isPause(at: start - 1, in: segments) else { return nil }

        for command in commands {
            if let end = end(of: command, at: start, in: segments, language: language), isPause(at: end + 1, in: segments) {
                return (command, end)
            }
        }

        return nil
    }

    private static func end(of command: Command, at start: Int, in segments: [TextSegment], language: Language) -> Int? {
        var index = start

        for (position, word) in command.words.enumerated() {
            if position > 0 {
                guard index + 2 < segments.count, segments[index + 1].text.allSatisfy(\.isWhitespace) else { return nil }

                index += 2
            }

            guard segments[index].isWord, segments[index].text.normalizedWord(in: language) == word else { return nil }
        }

        return index
    }

    private static func isPause(at index: Int, in segments: [TextSegment]) -> Bool {
        !segments.indices.contains(index) || segments[index].text.contains { $0.isPauseMark || $0 == "\n" }
    }

    private static func endingLine(_ text: String, language: Language, isParagraph: Bool) -> String {
        var line = text

        while let last = line.last, last == " " || joiningMarks.contains(last) {
            line.removeLast()
        }

        return isParagraph ? line.endingWithFullStop(in: language) : line
    }
}
