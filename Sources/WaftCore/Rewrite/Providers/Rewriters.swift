package struct Rewriters: Sendable {
    private let cloud: PerProvider<any TextRewriter>
    private let localServer: any TextRewriter

    package init(cloud: PerProvider<any TextRewriter>, localServer: any TextRewriter) {
        self.cloud = cloud
        self.localServer = localServer
    }

    package subscript(_ provider: ModelProvider) -> any TextRewriter {
        switch provider {
        case .localServer: localServer
        case let .cloud(provider): cloud[provider]
        }
    }
}
