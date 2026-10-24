import Testing
@testable import WaftCore

struct AppModeOverridesTests {
    @Test
    func `lists the apps in order and forgets an app set to no mode`() {
        var overrides = AppModeOverrides()
        overrides.set(.raw, for: "com.apple.mail")
        overrides.set(.formal, for: "com.apple.Notes")
        overrides.set(.clean, for: "com.apple.dt.Xcode")
        overrides.set(nil, for: "com.apple.Notes")

        #expect(overrides.bundleIdentifiers == ["com.apple.dt.Xcode", "com.apple.mail"])
        #expect(overrides.mode(for: "com.apple.Notes") == nil)
        #expect(overrides.mode(for: "com.apple.mail") == .raw)
    }

    @Test
    func `adds an app with the given mode`() {
        var overrides = AppModeOverrides()
        overrides.add(.raw, for: "com.apple.Notes")

        #expect(overrides.mode(for: "com.apple.Notes") == .raw)
    }

    @Test
    func `keeps the mode of an app that is added again`() {
        var overrides = AppModeOverrides()
        overrides.set(.formal, for: "com.apple.Notes")
        overrides.add(.raw, for: "com.apple.Notes")

        #expect(overrides.mode(for: "com.apple.Notes") == .formal)
    }

    @Test
    func `has no mode for an app without a bundle identifier`() {
        var overrides = AppModeOverrides()
        overrides.set(.raw, for: "")

        #expect(overrides.mode(for: nil) == nil)
    }
}
