import WaftCore

extension SpeechModelState {
    static let readyEvents: [Event] = [.started(.fast, isInstalled: true), .loaded(.fast)]

    init(after events: [Event]) {
        self.init()

        for event in events {
            _ = handle(event)
        }
    }
}
