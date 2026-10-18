import WaftCore

extension TranscriptProcessor {
    static func answering(_ claude: Result<String, RewriteError>, log: RewriteLog) -> TranscriptProcessor {
        TranscriptProcessor(rewriters: Rewriters(
            cloud: PerProvider(
                claude: FakeTextRewriter(answer: claude, log: log),
                openAI: FakeTextRewriter(answer: .success("From OpenAI."), log: log),
            ),
            localServer: FakeTextRewriter(answer: .success("From the local server."), log: log),
        ))
    }
}
