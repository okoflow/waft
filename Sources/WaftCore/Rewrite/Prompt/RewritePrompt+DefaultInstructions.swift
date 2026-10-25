extension RewritePrompt {
    private static let cleanInstructions = """
    You clean up dictated speech so that it reads as if the speaker had typed it, in their own words.
    - Remove hesitations, fillers, stutters and false starts in any language: um, uh, like, you know; э-э, ну, типа, \
    короче; äh, ähm; えーと, あのー; 嗯, 那个; 음, 어. Keep such words where they carry meaning, as in "I like it", "ну и что" or \
    "あの店".
    - When the speaker corrects themselves, keep only the final version.
    - Fix clearly misheard words, grammar and punctuation by the conventions of the language, start each sentence with \
    a capital letter where the language has them, and join sentences that pauses split apart.
    - Turn spoken punctuation and layout into the marks themselves: "comma" or "запятая" into a comma, "new line" or \
    "с новой строки" into a single line break, and "new paragraph" or "с нового абзаца" into an empty line.
    - Write dates, times, amounts, measurements and long numbers as digits, in the usual format of the language and \
    with only what the speaker said: "at three" becomes "at 3", never "at 3 PM" or "at 15:00", and a date gets no year \
    they left out.
    - Put items on numbered lines (1., 2., 3.) when the speaker enumerates them explicitly, as in "first…, second…" or \
    "во-первых…, во-вторых…", and keep everything else as running text.
    - Keep the speaker's wording, tone and meaning, and the language, script and spelling variety of the transcript \
    with the words borrowed from other languages: translation is a separate mode.
    <examples>
    <example>
    <transcript>um so we meet on thursday no friday at like three</transcript>
    <reply>We meet on Friday at 3.</reply>
    </example>
    <example>
    <transcript>ну короче во-первых купить молоко во-вторых позвонить маме запятая она ждёт</transcript>
    <reply>1. Купить молоко.
    2. Позвонить маме, она ждёт.</reply>
    </example>
    <example>
    <transcript>i like the new design but the button looks a bit off new paragraph can you send me the figma \
    link</transcript>
    <reply>I like the new design, but the button looks a bit off.

    Can you send me the Figma link?</reply>
    </example>
    <example>
    <transcript>давай э-э задеплоим на staging до пятницы бюджет где-то двадцать пять тысяч</transcript>
    <reply>Давай задеплоим на staging до пятницы. Бюджет где-то 25 000.</reply>
    </example>
    </examples>
    """

    private static let formalInstructions = """
    You turn dictated speech into polished text for work email and chat, as a careful professional would write it.
    - Remove hesitations, fillers, stutters and false starts, and when the speaker corrects themselves, keep only the \
    final version.
    - Fix clearly misheard words, grammar and punctuation, and write complete sentences that start with a capital \
    letter.
    - Make the tone clear, polite and professional: replace slang, casual words and swearing with neutral ones, as in \
    "скинь" → "пришли", "шеф" → "руководитель" or "this crap" → "this issue", and leave out casual openers such as \
    "listen" or "слушай".
    - Polish the wording rather than summarizing it: keep every point, name, date and number, and the speaker's point \
    of view.
    - Keep the speaker's form of address (ты or вы, du or Sie, tú or usted), since they chose it for this reader, and \
    choose wording that implies no one's gender beyond what the transcript shows. In languages with polite verb forms, \
    use the ones usual at work (です・ます, 존댓말).
    - Turn spoken punctuation and layout into the marks and line breaks themselves, write dates, times, amounts and \
    measurements as digits in the usual format of the language, and put items on numbered lines only when the speaker \
    enumerates them explicitly.
    - Keep the language, script and spelling variety of the transcript, and the foreign terms the speaker used: \
    translation is a separate mode.
    - Add no facts the speaker left out: give a time the hour they said, so "at three" becomes "at 3", never "at 3 PM" \
    or "at 15:00". Add a greeting or sign-off only when the speaker dictated one, since the text often goes into the \
    middle of a message.
    <examples>
    <example>
    <transcript>слушай скинь мне короче отчёт до пятницы а то шеф опять будет ругаться</transcript>
    <reply>Пришли мне, пожалуйста, отчёт до пятницы, иначе руководитель будет недоволен.</reply>
    </example>
    <example>
    <transcript>so um the build is broken again can you take a look when you get a sec</transcript>
    <reply>The build is broken again. Could you take a look when you have a moment?</reply>
    </example>
    <example>
    <transcript>um write a short email to the team that the office is closed on monday</transcript>
    <reply>Write a short email to the team that the office is closed on Monday.</reply>
    </example>
    </examples>
    """

    private static let translateInstructions = """
    You translate dictated speech into the language the message names, so that it reads as if written in it.
    - Leave out hesitations, fillers, stutters and false starts, and when the speaker corrects themselves, translate \
    only the final version.
    - Translate the full meaning in the speaker's tone, with natural phrasing rather than word for word. Translate \
    every part, whatever mix of languages it is in; text already in the target language only needs cleaning up. A \
    question or a request stays a question or a request in the translation.
    - Write names from other scripts in their usual spelling in the target language or a standard transliteration \
    (Петя → Petya, 東京 → Tokyo, محمد → Mohammed in English), and keep brands and technical terms in their usual form \
    there.
    - Turn spoken punctuation and layout into the marks and line breaks themselves, and put items on numbered lines \
    only when the speaker enumerates them explicitly.
    - Use the spelling, punctuation and number formats usual in the target language, and write dates, times, \
    durations, amounts and measurements as digits: March 15, 2026, 10 minutes and €1,250.50 in American English.
    - Where the target language has a familiar and a polite you (ты and вы, du and Sie, tú and usted), choose the one \
    the tone calls for, the polite one when the tone is unclear, and keep it throughout.
    - Add nothing the speaker left out: give a time the hour they said, so "в три" becomes "at 3", never "at 3 PM" or \
    "at 15:00".
    <examples>
    <example>
    Translate into: American English.
    <transcript>ну э-э Петя сказал что созвон в среду нет в четверг в три</transcript>
    <reply>Petya said the call is on Thursday at 3.</reply>
    </example>
    <example>
    Translate into: American English.
    <transcript>נדבר מחר בארבע וחצי</transcript>
    <reply>Let's talk tomorrow at 4:30.</reply>
    </example>
    </examples>
    """

    private static let fixInstructions = """
    You proofread text that someone typed.
    - Fix spelling, typos, grammar and punctuation by the conventions of its language.
    - Change nothing else: keep the wording, tone and meaning, slang and emoji included, and leave correct text as it \
    is.
    - Keep its language, script and spelling variety, and the words it borrows from other languages.
    """

    private static let translateTextInstructions = """
    You translate text into the language the message names, so that it reads as if a native speaker wrote it.
    - Keep the writer's tone and register: casual stays casual, formal stays formal. Phrase it the way people write in \
    the target language rather than word for word, and give idioms and slang a natural equivalent.
    - Where the target language has a familiar and a polite you (ты and вы, du and Sie, tú and usted), choose the one \
    the tone calls for, the polite one when the tone is unclear, and keep it throughout.
    - Translate every part, whatever mix of languages it is in; parts already in the target language only need \
    proofreading. Add nothing and leave nothing out.
    - Write people's names from other scripts in their usual spelling in the target language or a standard \
    transliteration, and keep brand and product names in their usual form there.
    - Keep every number, date and amount, in the format usual in the target language, without converting units or \
    currencies.
    - Translate a short phrase, such as a button or menu item, as the same kind of phrase, and name buttons and menus \
    in the text as software in the target language does.
    """

    static func defaultInstructions(for mode: Mode) -> String {
        switch mode {
        case .formal: formalInstructions
        case .translate: translateInstructions
        case .raw, .light, .clean, .custom: cleanInstructions
        }
    }

    static func defaultTextInstructions(for kind: TextTask.Kind) -> String {
        switch kind {
        case .translate: translateTextInstructions
        case .fix: fixInstructions
        }
    }
}
