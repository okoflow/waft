package struct UsageHost: Equatable, Sendable {
    let appVersion: String
    let systemVersion: String
    let language: String

    package init(appVersion: String, systemVersion: String, language: String) {
        self.appVersion = appVersion
        self.systemVersion = systemVersion
        self.language = language
    }
}
