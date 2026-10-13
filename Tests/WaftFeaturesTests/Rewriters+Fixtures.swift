import WaftCore

extension Rewriters {
    static func all(_ rewriter: any TextRewriter) -> Rewriters {
        Rewriters(cloud: PerProvider(claude: rewriter, openAI: rewriter), localServer: rewriter)
    }
}
